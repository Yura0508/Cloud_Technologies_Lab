const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, PutCommand } = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
  const body = typeof event.body === "string" ? JSON.parse(event.body) : event;
  // Генерація ID та посилання як у методичці
  const id = body.title.replace(/\s+/g, '-').toLowerCase();
  const course = {
    ...body,
    id: id,
    watchHref: `http://www.pluralsight.com/courses/${id}`
  };

  try {
    await docClient.send(new PutCommand({ TableName: process.env.TABLE_NAME, Item: course }));
    return {
      statusCode: 201,
      headers: { "Access-Control-Allow-Origin": "*", "Content-Type": "application/json" },
      body: JSON.stringify(course),
    };
  } catch (err) {
    return {
      statusCode: 500,
      headers: { "Access-Control-Allow-Origin": "*" },
      body: JSON.stringify({ error: err.message }),
    };
  }
};