const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, PutCommand } = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
    const tableName = process.env.TABLE_NAME;
    const body = JSON.parse(event.body);

    const params = {
        TableName: tableName,
        Item: {
            id: body.id,
            title: body.title,
            authorId: body.authorId,
            length: body.length,
            category: body.category
        },
    };

    try {
        await docClient.send(new PutCommand(params));
        return {
            statusCode: 201,
            body: JSON.stringify({ message: "Course saved successfully!", course: params.Item }),
        };
    } catch (err) {
        return {
            statusCode: 500,
            body: JSON.stringify({ error: err.message }),
        };
    }
};
