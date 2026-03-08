const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, PutCommand } = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
  const body = typeof event.body === "string" ? JSON.parse(event.body) : event;
  try {
    await docClient.send(new PutCommand({ TableName: process.env.TABLE_NAME, Item: body }));
    return {
      statusCode: 200,
      headers: { "Access-Control-Allow-Origin": "*", "Content-Type": "application/json" },
      body: JSON.stringify(body),
    };
  } catch (err) {
    return {
      statusCode: 500,
      headers: { "Access-Control-Allow-Origin": "*" },
      body: JSON.stringify({ error: err.message }),
    };
  }
};