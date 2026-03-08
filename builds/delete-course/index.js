const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, DeleteCommand } = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
    const tableName = process.env.TABLE_NAME;
    // В Proxy інтеграції ID приходить у pathParameters
    const courseId = event.pathParameters?.id || event.id; 

    if (!courseId) {
        return { statusCode: 400, body: JSON.stringify({ error: "Missing ID" }) };
    }

    const params = {
        TableName: tableName,
        Key: { id: courseId }, // 'id' має бути рядком
    };

    try {
        await docClient.send(new DeleteCommand(params));
        return {
            statusCode: 200,
            headers: { "Access-Control-Allow-Origin": "*", "Content-Type": "application/json" },
            body: JSON.stringify({ message: "Course deleted successfully", id: courseId }),
        };
    } catch (err) {
        return { statusCode: 500, body: JSON.stringify({ error: err.message }) };
    }
};