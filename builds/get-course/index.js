const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, GetCommand } = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
    const tableName = process.env.TABLE_NAME;
    const courseId = event.pathParameters?.id || event.id; // Для тестів або API Gateway

    const params = {
        TableName: tableName,
        Key: { id: courseId },
    };

    try {
        const data = await docClient.send(new GetCommand(params));
        if (!data.Item) {
            return { statusCode: 404, body: JSON.stringify({ message: "Course not found" }) };
        }
        return {
            statusCode: 200,
            headers: { "Access-Control-Allow-Origin": "*" },
            body: JSON.stringify(data.Item),
        };
    } catch (err) {
        return { statusCode: 500, body: JSON.stringify({ error: err.message }) };
    }
};
