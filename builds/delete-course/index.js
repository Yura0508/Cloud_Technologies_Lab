const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, GetCommand, DeleteCommand } = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
  const id = event.pathParameters?.id || event.id;

  try {
    const check = await docClient.send(new GetCommand({ 
      TableName: process.env.TABLE_NAME, 
      Key: { id } 
    }));

    if (!check.Item) {
      console.error(`ERROR: Спроба видалення неіснуючого курсу: ${id}`);
      return { 
        statusCode: 404, 
        headers: { "Access-Control-Allow-Origin": "*" },
        body: JSON.stringify({ error: "Курс не знайдено" }) 
      };
    }

    await docClient.send(new DeleteCommand({ TableName: process.env.TABLE_NAME, Key: { id } }));
    return { 
      statusCode: 200, 
      headers: { "Access-Control-Allow-Origin": "*" },
      body: JSON.stringify({ message: "Успішно видалено", id }) 
    };
  } catch (err) {
    console.error("ERROR: ", err.message);
    return { statusCode: 500, body: JSON.stringify({ error: err.message }) };
  }
};