const https = require('https');
const zlib = require('zlib');

exports.handler = async (event) => {
    let message = "⚠️ Сповіщення від моніторингу";
    console.log("Отримано івент:", JSON.stringify(event));

    try {
        if (event.awslogs) {
            const payload = Buffer.from(event.awslogs.data, 'base64');
            const decompressed = zlib.gunzipSync(payload);
            const data = JSON.parse(decompressed.toString());
            const logEvent = data.logEvents[0];
            message = `🚨 *ВИЯВЛЕНО ПОМИЛКУ*\n\n*Функція:* \`${data.logGroup}\`\n*Повідомлення:* \`${logEvent.message}\``;
        } 
        else if (event.Records && event.Records[0].Sns) {
            const sns = event.Records[0].Sns;
            message = `💰 *AWS Alert:* ${sns.Subject}\n\n${sns.Message}`;
        }

        const slackData = JSON.stringify({ text: message });
        const webhookUrl = process.env.SLACK_WEBHOOK_URL;
        
        console.log("Відправляємо у Slack за адресою:", webhookUrl);

        const options = {
            hostname: 'hooks.slack.com',
            path: new URL(webhookUrl).pathname,
            method: 'POST',
            headers: { 'Content-Type': 'application/json' }
        };

        return new Promise((resolve, reject) => {
            const req = https.request(options, (res) => {
                res.on('data', () => resolve("Sent"));
            });
            req.on('error', (e) => reject(e));
            req.write(slackData);
            req.end();
        });
    } catch (e) { 
        console.error("КРИТИЧНА ПОМИЛКА NOTIFIER:", e.message); 
    }
};
