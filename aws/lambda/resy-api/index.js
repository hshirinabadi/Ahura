const AWS = require('aws-sdk');
const axios = require('axios');

const secretsManager = new AWS.SecretsManager();
const dynamoDB = new AWS.DynamoDB.DocumentClient();

const RESY_API_KEY = process.env.RESY_API_KEY;
const RESY_API_URL = 'https://api.resy.com/3';

// Helper function to get Resy API credentials
async function getResyCredentials() {
    const secretName = 'resy/api-credentials';
    const data = await secretsManager.getSecretValue({ SecretId: secretName }).promise();
    return JSON.parse(data.SecretString);
}

// Helper function to make authenticated Resy API calls
async function callResyAPI(method, endpoint, data = null) {
    const credentials = await getResyCredentials();
    
    const headers = {
        'Authorization': `Bearer ${credentials.apiKey}`,
        'Content-Type': 'application/json',
        'x-resy-auth-token': credentials.authToken
    };
    
    try {
        const response = await axios({
            method,
            url: `${RESY_API_URL}${endpoint}`,
            headers,
            data
        });
        
        return response.data;
    } catch (error) {
        console.error('Resy API Error:', error.response?.data || error.message);
        throw error;
    }
}

// Lambda handler
exports.handler = async (event) => {
    try {
        const { path, httpMethod, body } = event;
        const requestBody = body ? JSON.parse(body) : null;
        
        switch (path) {
            case '/venues/search':
                if (httpMethod === 'POST') {
                    const searchResults = await callResyAPI('POST', '/venues/search', requestBody);
                    return {
                        statusCode: 200,
                        body: JSON.stringify(searchResults)
                    };
                }
                break;
                
            case '/venues/{id}':
                if (httpMethod === 'GET') {
                    const venueId = event.pathParameters.id;
                    const venueDetails = await callResyAPI('GET', `/venues/${venueId}`);
                    return {
                        statusCode: 200,
                        body: JSON.stringify(venueDetails)
                    };
                }
                break;
                
            case '/reservations/book':
                if (httpMethod === 'POST') {
                    const bookingResult = await callResyAPI('POST', '/reservations', requestBody);
                    
                    // Store reservation in DynamoDB
                    await dynamoDB.put({
                        TableName: 'Reservations',
                        Item: {
                            id: bookingResult.reservation_id,
                            userId: event.requestContext.authorizer.claims.sub,
                            venueId: requestBody.venue_id,
                            date: requestBody.date,
                            partySize: requestBody.party_size,
                            status: 'confirmed',
                            createdAt: new Date().toISOString()
                        }
                    }).promise();
                    
                    return {
                        statusCode: 200,
                        body: JSON.stringify(bookingResult)
                    };
                }
                break;
        }
        
        return {
            statusCode: 404,
            body: JSON.stringify({ message: 'Not Found' })
        };
        
    } catch (error) {
        console.error('Lambda Error:', error);
        
        return {
            statusCode: error.response?.status || 500,
            body: JSON.stringify({
                message: error.response?.data?.message || 'Internal Server Error'
            })
        };
    }
}; 