const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, QueryCommand } = require('@aws-sdk/lib-dynamodb');
const axios = require('axios');

const secretsManager = new SecretsManagerClient({ region: process.env.REGION });
const dynamoDb = DynamoDBDocumentClient.from(new DynamoDBClient({ region: process.env.REGION }));

const RESY_API_URL = 'https://api.resy.com/3';

// Helper function to get Resy API credentials
async function getResyCredentials() {
    const secretName = `resy/api-credentials-${process.env.Environment}`;
    const command = new GetSecretValueCommand({ SecretId: secretName });
    const response = await secretsManager.send(command);
    return JSON.parse(response.SecretString);
}

// Helper function to make authenticated Resy API calls
async function callResyAPI(method, endpoint, data = null, authToken, queryParams = null) {
    const credentials = await getResyCredentials();
    
    const headers = {
        'Authorization': `ResyAPI api_key="${credentials.apiKey}"`,
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*',
        'Origin': 'https://resy.com',
        'Referer': 'https://resy.com/',
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15',
        'X-Origin': 'https://resy.com'
    };
    
    if (authToken) {
        headers['x-resy-auth-token'] = authToken;
    }
    
    try {
        console.log(`Calling Resy API: ${method} ${endpoint}`);
        console.log('Headers:', headers);
        if (data) console.log('Data:', data);
        if (queryParams) console.log('Query Params:', queryParams);
        
        // Construct URL with query parameters if provided
        let url = `${RESY_API_URL}${endpoint}`;
        if (queryParams) {
            const queryString = new URLSearchParams(queryParams).toString();
            url = `${url}?${queryString}`;
        }
        
        const response = await axios({
            method,
            url,
            headers,
            data
        });
        
        console.log('Resy API Response:', response.data);
        return response.data;
    } catch (error) {
        console.error('Resy API Error:', {
            status: error.response?.status,
            data: error.response?.data,
            message: error.message
        });
        throw error;
    }
}

// Helper function to get user reservations from Resy API
async function getUserReservations(authToken, type = null) {
    try {
        console.log('Getting user reservations with token:', authToken);
        
        // Set up query parameters based on type
        const queryParams = {
            limit: 10,
            offset: 0,
            book_on_behalf_of: false
        };
        
        if (type) {
            queryParams.type = type;
        }
        
        const response = await callResyAPI('GET', '/user/reservations', null, authToken, queryParams);
        
        if (!response.reservations) {
            console.error('Unexpected Resy API response:', response);
            throw new Error('Invalid response format from Resy API');
        }
        
        return response.reservations.map(reservation => ({
            id: reservation.resy_token,
            venue_id: reservation.venue.id,
            venue_name: reservation.venue.name,
            date: reservation.date,
            time: reservation.time,
            party_size: reservation.party_size,
            status: reservation.status,
            created_at: reservation.created_at
        }));
    } catch (error) {
        console.error('Error fetching user reservations:', error);
        throw error;
    }
}

// Helper function to query DynamoDB
async function queryReservations(userId, isPast = false) {
    const now = new Date().toISOString();
    const params = {
        TableName: `Reservations-${process.env.Environment}`,
        IndexName: 'UserReservations',
        KeyConditionExpression: 'userId = :userId',
        FilterExpression: isPast ? '#date < :now' : '#date >= :now',
        ExpressionAttributeNames: {
            '#date': 'reservationDate'
        },
        ExpressionAttributeValues: {
            ':userId': userId,
            ':now': now
        }
    };

    const command = new QueryCommand(params);
    const response = await dynamoDb.send(command);
    return response.Items;
}

// Helper function to map Resy status to our app status
function mapResyStatusToAppStatus(resyStatus) {
    switch (resyStatus) {
        case 'confirmed':
            return 'confirmed';
        case 'pending':
            return 'pending';
        case 'cancelled':
            return 'cancelled';
        case 'completed':
            return 'completed';
        default:
            return 'pending';
    }
}

// Helper function to filter reservations by date
function filterReservationsByDate(reservations, isPast = false) {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    
    return reservations.filter(reservation => {
        const reservationDate = new Date(reservation.date);
        return isPast ? reservationDate < today : reservationDate >= today;
    });
}

// Lambda handler
exports.handler = async (event) => {
    console.log('Received event:', JSON.stringify(event, null, 2));
    
    try {
        const path = event.path;
        const authToken = event.headers?.['x-resy-auth-token'];
        const type = event.queryStringParameters?.type; // 'past' or 'upcoming'
        
        if (!authToken) {
            console.error('No auth token provided');
            return {
                statusCode: 401,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                body: JSON.stringify({
                    message: 'Missing authentication token'
                })
            };
        }
        
        let reservations;
        
        try {
            // Get reservations with type parameter if provided
            reservations = await getUserReservations(authToken, type);
            console.log('Retrieved reservations:', reservations);
            
            switch (path) {
                case '/reservations':
                    break;
                    
                case '/reservations/past':
                    // If type is not already set to 'past', filter the results
                    if (type !== 'past') {
                        const now = new Date();
                        reservations = reservations.filter(res => new Date(res.date) < now);
                    }
                    break;
                    
                case '/reservations/upcoming':
                    // If type is not already set to 'upcoming', filter the results
                    if (type !== 'upcoming') {
                        const today = new Date();
                        reservations = reservations.filter(res => new Date(res.date) >= today);
                    }
                    break;
                    
                case '/venues/search':
                    if (event.httpMethod === 'POST') {
                        const searchResults = await callResyAPI('POST', '/venues/search', JSON.parse(event.body), authToken);
                        return {
                            statusCode: 200,
                            headers: {
                                'Content-Type': 'application/json',
                                'Access-Control-Allow-Origin': '*'
                            },
                            body: JSON.stringify(searchResults)
                        };
                    }
                    break;
                    
                case '/venues/{id}':
                    if (event.httpMethod === 'GET') {
                        const venueId = event.pathParameters.id;
                        const venueDetails = await callResyAPI('GET', `/venues/${venueId}`, null, authToken);
                        return {
                            statusCode: 200,
                            headers: {
                                'Content-Type': 'application/json',
                                'Access-Control-Allow-Origin': '*'
                            },
                            body: JSON.stringify(venueDetails)
                        };
                    }
                    break;
                    
                case '/reservations/book':
                    if (event.httpMethod === 'POST') {
                        const bookingResult = await callResyAPI('POST', '/reservations', JSON.parse(event.body), authToken);
                        
                        // Store reservation in DynamoDB for backup/quick access
                        await dynamoDb.put({
                            TableName: `Reservations-${process.env.Environment}`,
                            Item: {
                                id: bookingResult.reservation_id,
                                userId: event.requestContext.authorizer?.claims?.sub || 'test-user',
                                venueId: JSON.parse(event.body).venue_id,
                                date: JSON.parse(event.body).date,
                                partySize: JSON.parse(event.body).party_size,
                                status: 'confirmed',
                                createdAt: new Date().toISOString()
                            }
                        });
                        
                        return {
                            statusCode: 200,
                            headers: {
                                'Content-Type': 'application/json',
                                'Access-Control-Allow-Origin': '*'
                            },
                            body: JSON.stringify(bookingResult)
                        };
                    }
                    break;
                    
                default:
                    return {
                        statusCode: 404,
                        headers: {
                            'Content-Type': 'application/json',
                            'Access-Control-Allow-Origin': '*'
                        },
                        body: JSON.stringify({ message: 'Not Found' })
                    };
            }
            
            return {
                statusCode: 200,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                body: JSON.stringify({ reservations })
            };
            
        } catch (resyError) {
            console.error('Resy API error:', resyError);
            
            // Handle Resy API specific errors
            if (resyError.response?.status === 401) {
                return {
                    statusCode: 401,
                    headers: {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    },
                    body: JSON.stringify({
                        message: 'Invalid or expired Resy authentication token'
                    })
                };
            }
            
            throw resyError; // Let the outer catch handle other errors
        }
    } catch (error) {
        console.error('Lambda error:', error);
        
        return {
            statusCode: error.response?.status || 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                message: error.response?.data?.message || 'Internal Server Error',
                error: error.message
            })
        };
    }
}; 