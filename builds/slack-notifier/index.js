const https = require('https');

exports.handler = async (event) => {
    // Логуємо вхідну подію для перевірки
    console.log("SNS Event received:", JSON.stringify(event, null, 2));

    try {
        const snsMessage = event.Records[0].Sns.Message;
        const snsSubject = event.Records[0].Sns.Subject || "AWS Alert";
        
        // Формуємо об'єкт повідомлення
        const slackObject = {
            text: `Attention: *${snsSubject}*\n\n*Деталі:* \n\`\`\`${snsMessage}\`\`\``,
            username: "AWS Monitoring Bot",
            icon_emoji: ":aws:"
        };

        const slackData = JSON.stringify(slackObject);
        const webhookUrl = process.env.SLACK_WEBHOOK_URL;

        // Витягуємо тільки шлях (/services/...)
        const urlPath = webhookUrl.includes('hooks.slack.com') 
                        ? webhookUrl.split('hooks.slack.com')[1] 
                        : webhookUrl;

        const options = {
            hostname: 'hooks.slack.com',
            path: urlPath,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                // ВАЖЛИВО: використовуємо Buffer.byteLength для коректного розміру з емодзі
                'Content-Length': Buffer.byteLength(slackData),
            },
        };

        return new Promise((resolve, reject) => {
            const req = https.request(options, (res) => {
                let resBody = '';
                res.on('data', (chunk) => resBody += chunk);
                res.on('end', () => {
                    console.log(`Slack Response: ${res.statusCode} ${resBody}`);
                    if (res.statusCode === 200) {
                        resolve("Message Sent");
                    } else {
                        reject(new Error(`Slack error: ${res.statusCode} ${resBody}`));
                    }
                });
            });

            req.on('error', (e) => {
                console.error("HTTP Request Error:", e);
                reject(e);
            });

            req.write(slackData);
            req.end();
        });
    } catch (error) {
        console.error("Handler Error:", error);
        throw error;
    }
};