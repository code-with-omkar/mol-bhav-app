using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MolBhav.Infrastructure.Persistence.Migrations
{
    /// <summary>
    /// Help &amp; Support copy seeded into the LocalizedTexts store (BRD §8/§18): ten Q&amp;A pairs under
    /// <c>support.faq.{n}.q</c>/<c>.a</c>, which the app fetches with
    /// <c>GET /api/v1/localization/texts?keyPrefix=support.faq.</c>, plus the two keys
    /// <c>SupportReplyNotificationHandler</c> resolves for its push copy. Ids are fixed literals so every environment
    /// gets identical ones, and both tables are seeded under one sentinel <c>created_by</c> so <c>Down</c> is exact.
    /// Editable afterwards through the admin localization endpoints — this is a starting point, not a fixture.
    /// </summary>
    public partial class SeedSupportFaq : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                INSERT INTO localization.localized_text_entries (id, key, description, created_at_utc, created_by, updated_at_utc, updated_by) VALUES
                    ('b1f0a001-0000-5000-8000-000000000001', 'support.faq.1.q',  'Help & Support FAQ 1 — question', TIMESTAMPTZ '2026-09-27 02:56:28+00', '8c1e5a42-77bd-4f0a-9a3e-2c6f1b7d4e91', NULL, NULL),
                    ('b1f0a001-0000-5000-8000-000000000002', 'support.faq.1.a',  'Help & Support FAQ 1 — answer',   TIMESTAMPTZ '2026-09-27 02:56:28+00', '8c1e5a42-77bd-4f0a-9a3e-2c6f1b7d4e91', NULL, NULL),
                    ('b1f0a002-0000-5000-8000-000000000001', 'support.faq.2.q',  'Help & Support FAQ 2 — question', TIMESTAMPTZ '2026-09-27 02:56:28+00', '8c1e5a42-77bd-4f0a-9a3e-2c6f1b7d4e91', NULL, NULL),
                    ('b1f0a002-0000-5000-8000-000000000002', 'support.faq.2.a',  'Help & Support FAQ 2 — answer',   TIMESTAMPTZ '2026-09-27 02:56:28+00', '8c1e5a42-77bd-4f0a-9a3e-2c6f1b7d4e91', NULL, NULL),
                    ('b1f0a003-0000-5000-8000-000000000001', 'support.faq.3.q',  'Help & Support FAQ 3 — question', TIMESTAMPTZ '2026-09-27 02:56:28+00', '8c1e5a42-77bd-4f0a-9a3e-2c6f1b7d4e91', NULL, NULL),
                    ('b1f0a003-0000-5000-8000-000000000002', 'support.faq.3.a',  'Help & Support FAQ 3 — answer',   TIMESTAMPTZ '2026-09-27 02:56:28+00', '8c1e5a42-77bd-4f0a-9a3e-2c6f1b7d4e91', NULL, NULL),
                    ('b1f0a004-0000-5000-8000-000000000001', 'support.faq.4.q',  'Help & Support FAQ 4 — question', TIMESTAMPTZ '2026-09-27 02:56:28+00', '8c1e5a42-77bd-4f0a-9a3e-2c6f1b7d4e91', NULL, NULL),
                    ('b1f0a004-0000-5000-8000-000000000002', 'support.faq.4.a',  'Help & Support FAQ 4 — answer',   TIMESTAMPTZ '2026-09-27 02:56:28+00', '8c1e5a42-77bd-4f0a-9a3e-2c6f1b7d4e91', NULL, NULL),
                    ('b1f0a005-0000-5000-8000-000000000001', 'support.faq.5.q',  'Help & Support FAQ 5 — question', TIMESTAMPTZ '2026-09-27 02:56:28+00', '8c1e5a42-77bd-4f0a-9a3e-2c6f1b7d4e91', NULL, NULL),
                    ('b1f0a005-0000-5000-8000-000000000002', 'support.faq.5.a',  'Help & Support FAQ 5 — answer',   TIMESTAMPTZ '2026-09-27 02:56:28+00', '8c1e5a42-77bd-4f0a-9a3e-2c6f1b7d4e91', NULL, NULL),
                    ('b1f0a006-0000-5000-8000-000000000001', 'support.faq.6.q',  'Help & Support FAQ 6 — question', TIMESTAMPTZ '2026-09-27 02:56:28+00', '8c1e5a42-77bd-4f0a-9a3e-2c6f1b7d4e91', NULL, NULL),
                    ('b1f0a006-0000-5000-8000-000000000002', 'support.faq.6.a',  'Help & Support FAQ 6 — answer',   TIMESTAMPTZ '2026-09-27 02:56:28+00', '8c1e5a42-77bd-4f0a-9a3e-2c6f1b7d4e91', NULL, NULL),
                    ('b1f0a007-0000-5000-8000-000000000001', 'support.faq.7.q',  'Help & Support FAQ 7 — question', TIMESTAMPTZ '2026-09-27 02:56:28+00', '8c1e5a42-77bd-4f0a-9a3e-2c6f1b7d4e91', NULL, NULL),
                    ('b1f0a007-0000-5000-8000-000000000002', 'support.faq.7.a',  'Help & Support FAQ 7 — answer',   TIMESTAMPTZ '2026-09-27 02:56:28+00', '8c1e5a42-77bd-4f0a-9a3e-2c6f1b7d4e91', NULL, NULL),
                    ('b1f0a008-0000-5000-8000-000000000001', 'support.faq.8.q',  'Help & Support FAQ 8 — question', TIMESTAMPTZ '2026-09-27 02:56:28+00', '8c1e5a42-77bd-4f0a-9a3e-2c6f1b7d4e91', NULL, NULL),
                    ('b1f0a008-0000-5000-8000-000000000002', 'support.faq.8.a',  'Help & Support FAQ 8 — answer',   TIMESTAMPTZ '2026-09-27 02:56:28+00', '8c1e5a42-77bd-4f0a-9a3e-2c6f1b7d4e91', NULL, NULL),
                    ('b1f0a009-0000-5000-8000-000000000001', 'support.faq.9.q',  'Help & Support FAQ 9 — question', TIMESTAMPTZ '2026-09-27 02:56:28+00', '8c1e5a42-77bd-4f0a-9a3e-2c6f1b7d4e91', NULL, NULL),
                    ('b1f0a009-0000-5000-8000-000000000002', 'support.faq.9.a',  'Help & Support FAQ 9 — answer',   TIMESTAMPTZ '2026-09-27 02:56:28+00', '8c1e5a42-77bd-4f0a-9a3e-2c6f1b7d4e91', NULL, NULL),
                    ('b1f0a010-0000-5000-8000-000000000001', 'support.faq.10.q', 'Help & Support FAQ 10 — question', TIMESTAMPTZ '2026-09-27 02:56:28+00', '8c1e5a42-77bd-4f0a-9a3e-2c6f1b7d4e91', NULL, NULL),
                    ('b1f0a010-0000-5000-8000-000000000002', 'support.faq.10.a', 'Help & Support FAQ 10 — answer',   TIMESTAMPTZ '2026-09-27 02:56:28+00', '8c1e5a42-77bd-4f0a-9a3e-2c6f1b7d4e91', NULL, NULL),
                    ('b1f0b000-0000-5000-8000-000000000001', 'support.reply.title', 'Push title when support replies to a ticket', TIMESTAMPTZ '2026-09-27 02:56:28+00', '8c1e5a42-77bd-4f0a-9a3e-2c6f1b7d4e91', NULL, NULL),
                    ('b1f0b000-0000-5000-8000-000000000002', 'support.reply.body',  'Push body when support replies to a ticket',  TIMESTAMPTZ '2026-09-27 02:56:28+00', '8c1e5a42-77bd-4f0a-9a3e-2c6f1b7d4e91', NULL, NULL);
                """);

            migrationBuilder.Sql("""
                INSERT INTO localization.localized_text_values (text_entry_id, language_code, text) VALUES
                    ('b1f0a001-0000-5000-8000-000000000001', 'en', 'What does MolBhav do?'),
                    ('b1f0a001-0000-5000-8000-000000000001', 'hi', 'MolBhav क्या करता है?'),
                    ('b1f0a001-0000-5000-8000-000000000001', 'mr', 'MolBhav काय करते?'),
                    ('b1f0a001-0000-5000-8000-000000000002', 'en', 'It shows daily mandi and material prices near you, compares markets so you can see where a commodity is cheapest, and alerts you when a price you care about moves.'),
                    ('b1f0a001-0000-5000-8000-000000000002', 'hi', 'यह आपके आसपास की मंडियों और सामग्री के रोज़ के भाव दिखाता है, बाज़ारों की तुलना करता है ताकि आप देख सकें कि कहाँ सबसे सस्ता है, और आपके चुने हुए भाव में बदलाव पर आपको सूचित करता है।'),
                    ('b1f0a001-0000-5000-8000-000000000002', 'mr', 'हे तुमच्या जवळच्या मंड्या आणि साहित्याचे रोजचे भाव दाखवते, बाजारांची तुलना करते जेणेकरून कुठे सर्वात स्वस्त आहे ते दिसेल, आणि तुम्ही निवडलेल्या भावात बदल झाल्यावर कळवते.'),

                    ('b1f0a002-0000-5000-8000-000000000001', 'en', 'Where do the prices come from?'),
                    ('b1f0a002-0000-5000-8000-000000000001', 'hi', 'भाव कहाँ से आते हैं?'),
                    ('b1f0a002-0000-5000-8000-000000000001', 'mr', 'भाव कुठून येतात?'),
                    ('b1f0a002-0000-5000-8000-000000000002', 'en', 'Agricultural prices come from Agmarknet, the Government of India mandi price service. Construction material prices come from regional suppliers and hubs we work with. Every price on a screen names its source.'),
                    ('b1f0a002-0000-5000-8000-000000000002', 'hi', 'कृषि भाव भारत सरकार की Agmarknet मंडी भाव सेवा से आते हैं। निर्माण सामग्री के भाव हमारे साथ जुड़े क्षेत्रीय सप्लायर और हब से आते हैं। हर स्क्रीन पर भाव के साथ उसका स्रोत लिखा होता है।'),
                    ('b1f0a002-0000-5000-8000-000000000002', 'mr', 'शेती भाव भारत सरकारच्या Agmarknet मंडी भाव सेवेतून येतात. बांधकाम साहित्याचे भाव आमच्यासोबत असलेल्या प्रादेशिक पुरवठादार आणि हबकडून येतात. प्रत्येक स्क्रीनवर भावासोबत त्याचा स्रोत दिलेला असतो.'),

                    ('b1f0a003-0000-5000-8000-000000000001', 'en', 'How often are prices updated?'),
                    ('b1f0a003-0000-5000-8000-000000000001', 'hi', 'भाव कितनी बार अपडेट होते हैं?'),
                    ('b1f0a003-0000-5000-8000-000000000001', 'mr', 'भाव किती वेळा अपडेट होतात?'),
                    ('b1f0a003-0000-5000-8000-000000000002', 'en', 'Once a day for most mandis, on the day the mandi reports them. Every price shows the date it is for, so you always know how fresh it is.'),
                    ('b1f0a003-0000-5000-8000-000000000002', 'hi', 'ज़्यादातर मंडियों के लिए दिन में एक बार, जिस दिन मंडी भाव बताती है। हर भाव के साथ उसकी तारीख दिखाई जाती है, जिससे आपको पता रहे कि वह कितना ताज़ा है।'),
                    ('b1f0a003-0000-5000-8000-000000000002', 'mr', 'बहुतेक मंड्यांसाठी दिवसातून एकदा, ज्या दिवशी मंडी भाव कळवते. प्रत्येक भावासोबत त्याची तारीख दाखवली जाते, म्हणून तो किती ताजा आहे हे तुम्हाला कळते.'),

                    ('b1f0a004-0000-5000-8000-000000000001', 'en', 'How do I set a price alert?'),
                    ('b1f0a004-0000-5000-8000-000000000001', 'hi', 'भाव अलर्ट कैसे लगाऊँ?'),
                    ('b1f0a004-0000-5000-8000-000000000001', 'mr', 'भाव अलर्ट कसा लावायचा?'),
                    ('b1f0a004-0000-5000-8000-000000000002', 'en', 'Open Alerts, tap Create Alert, then pick a product and a mandi and say when to be told: below a price, above a price, or on a percent change. You can also start an alert straight from a comparison or trend screen.'),
                    ('b1f0a004-0000-5000-8000-000000000002', 'hi', 'Alerts खोलें, Create Alert दबाएँ, फिर उत्पाद और मंडी चुनें और बताएँ कि कब सूचित करें: किसी भाव से नीचे, किसी भाव से ऊपर, या प्रतिशत बदलाव पर। आप तुलना या ट्रेंड स्क्रीन से भी सीधे अलर्ट बना सकते हैं।'),
                    ('b1f0a004-0000-5000-8000-000000000002', 'mr', 'Alerts उघडा, Create Alert दाबा, नंतर उत्पादन आणि मंडी निवडा आणि कधी कळवायचे ते सांगा: एखाद्या भावाखाली, एखाद्या भावावर, किंवा टक्केवारी बदलावर. तुलना किंवा ट्रेंड स्क्रीनवरूनही तुम्ही थेट अलर्ट बनवू शकता.'),

                    ('b1f0a005-0000-5000-8000-000000000001', 'en', 'Why have I not received an alert?'),
                    ('b1f0a005-0000-5000-8000-000000000001', 'hi', 'मुझे अलर्ट क्यों नहीं मिला?'),
                    ('b1f0a005-0000-5000-8000-000000000001', 'mr', 'मला अलर्ट का मिळाला नाही?'),
                    ('b1f0a005-0000-5000-8000-000000000002', 'en', 'An alert fires only when a new price actually crosses your threshold — a price that was already past it does not fire again. Also check that the alert is active and that notifications are switched on under More.'),
                    ('b1f0a005-0000-5000-8000-000000000002', 'hi', 'अलर्ट तभी चलता है जब कोई नया भाव आपकी सीमा को पार करता है — जो भाव पहले से ही उस पार था, वह दोबारा अलर्ट नहीं करता। साथ ही देखें कि अलर्ट चालू है और More में नोटिफिकेशन चालू हैं।'),
                    ('b1f0a005-0000-5000-8000-000000000002', 'mr', 'नवीन भाव तुमची मर्यादा ओलांडतो तेव्हाच अलर्ट येतो — जो भाव आधीच पलीकडे होता तो पुन्हा अलर्ट करत नाही. तसेच अलर्ट चालू आहे का आणि More मध्ये नोटिफिकेशन चालू आहेत का ते तपासा.'),

                    ('b1f0a006-0000-5000-8000-000000000001', 'en', 'What do I get with MolBhav Pro?'),
                    ('b1f0a006-0000-5000-8000-000000000001', 'hi', 'MolBhav Pro में क्या मिलता है?'),
                    ('b1f0a006-0000-5000-8000-000000000001', 'mr', 'MolBhav Pro मध्ये काय मिळते?'),
                    ('b1f0a006-0000-5000-8000-000000000002', 'en', 'Price-history exports as CSV, a longer history window, and advanced alerts. The plan screen under More lists exactly what your plan includes today.'),
                    ('b1f0a006-0000-5000-8000-000000000002', 'hi', 'CSV में भाव-इतिहास का निर्यात, लंबी अवधि का इतिहास, और उन्नत अलर्ट। More में प्लान स्क्रीन पर आज आपके प्लान में जो शामिल है, वह पूरा दिखाया जाता है।'),
                    ('b1f0a006-0000-5000-8000-000000000002', 'mr', 'CSV मध्ये भाव-इतिहास निर्यात, जास्त कालावधीचा इतिहास, आणि प्रगत अलर्ट. More मधील प्लॅन स्क्रीनवर आज तुमच्या प्लॅनमध्ये काय समाविष्ट आहे ते दिसते.'),

                    ('b1f0a007-0000-5000-8000-000000000001', 'en', 'How do I change the app language?'),
                    ('b1f0a007-0000-5000-8000-000000000001', 'hi', 'ऐप की भाषा कैसे बदलूँ?'),
                    ('b1f0a007-0000-5000-8000-000000000001', 'mr', 'ॲपची भाषा कशी बदलायची?'),
                    ('b1f0a007-0000-5000-8000-000000000002', 'en', 'Your language is set during sign-in and is saved on your profile. Edit it from More, where it also decides the language of your alerts, WhatsApp messages and reports.'),
                    ('b1f0a007-0000-5000-8000-000000000002', 'hi', 'आपकी भाषा साइन-इन के समय चुनी जाती है और आपकी प्रोफ़ाइल में सहेजी जाती है। इसे More से बदलें; यही भाषा आपके अलर्ट, WhatsApp संदेश और रिपोर्ट में भी उपयोग होती है।'),
                    ('b1f0a007-0000-5000-8000-000000000002', 'mr', 'तुमची भाषा साइन-इन करताना निवडली जाते आणि तुमच्या प्रोफाइलमध्ये साठवली जाते. ती More मधून बदला; तीच भाषा तुमचे अलर्ट, WhatsApp संदेश आणि अहवालात वापरली जाते.'),

                    ('b1f0a008-0000-5000-8000-000000000001', 'en', 'How do I change my procurement categories?'),
                    ('b1f0a008-0000-5000-8000-000000000001', 'hi', 'मैं अपनी खरीद श्रेणियाँ कैसे बदलूँ?'),
                    ('b1f0a008-0000-5000-8000-000000000001', 'mr', 'माझ्या खरेदी श्रेणी कशा बदलायच्या?'),
                    ('b1f0a008-0000-5000-8000-000000000002', 'en', 'Go to More, then My categories. Your categories decide which products Home, comparison and alerts show first, and you can change them whenever your business does.'),
                    ('b1f0a008-0000-5000-8000-000000000002', 'hi', 'More में जाएँ, फिर My categories। आपकी श्रेणियाँ तय करती हैं कि Home, तुलना और अलर्ट में कौन-से उत्पाद पहले दिखें, और आप इन्हें जब चाहें बदल सकते हैं।'),
                    ('b1f0a008-0000-5000-8000-000000000002', 'mr', 'More मध्ये जा, नंतर My categories. तुमच्या श्रेणी ठरवतात की Home, तुलना आणि अलर्टमध्ये कोणती उत्पादने आधी दिसतील, आणि तुम्ही त्या कधीही बदलू शकता.'),

                    ('b1f0a009-0000-5000-8000-000000000001', 'en', 'Can I download price history?'),
                    ('b1f0a009-0000-5000-8000-000000000001', 'hi', 'क्या मैं भाव-इतिहास डाउनलोड कर सकता हूँ?'),
                    ('b1f0a009-0000-5000-8000-000000000001', 'mr', 'मी भाव-इतिहास डाउनलोड करू शकतो का?'),
                    ('b1f0a009-0000-5000-8000-000000000002', 'en', 'Yes. Under More, open Reports and generate a weekly summary as PDF, or a price history as CSV for one product and mandi. Reports are kept in your list, so you can download one again later.'),
                    ('b1f0a009-0000-5000-8000-000000000002', 'hi', 'हाँ। More में Reports खोलें और साप्ताहिक सारांश PDF में, या किसी एक उत्पाद और मंडी का भाव-इतिहास CSV में बनाएँ। रिपोर्ट आपकी सूची में रहती हैं, इसलिए आप उन्हें बाद में फिर डाउनलोड कर सकते हैं।'),
                    ('b1f0a009-0000-5000-8000-000000000002', 'mr', 'होय. More मध्ये Reports उघडा आणि साप्ताहिक सारांश PDF मध्ये, किंवा एका उत्पादन आणि मंडीचा भाव-इतिहास CSV मध्ये तयार करा. अहवाल तुमच्या यादीत राहतात, म्हणून तुम्ही ते नंतर पुन्हा डाउनलोड करू शकता.'),

                    ('b1f0a010-0000-5000-8000-000000000001', 'en', 'How do I reach a person?'),
                    ('b1f0a010-0000-5000-8000-000000000001', 'hi', 'किसी व्यक्ति से कैसे बात करूँ?'),
                    ('b1f0a010-0000-5000-8000-000000000001', 'mr', 'माणसाशी संपर्क कसा करायचा?'),
                    ('b1f0a010-0000-5000-8000-000000000002', 'en', 'Use WhatsApp, call or email us from this screen, or raise a ticket and we will answer inside the app. Tickets keep the whole conversation in one place, so nothing has to be explained twice.'),
                    ('b1f0a010-0000-5000-8000-000000000002', 'hi', 'इस स्क्रीन से WhatsApp करें, कॉल करें या ईमेल भेजें, या टिकट बनाएँ और हम ऐप में ही जवाब देंगे। टिकट में पूरी बातचीत एक जगह रहती है, इसलिए कुछ भी दो बार बताना नहीं पड़ता।'),
                    ('b1f0a010-0000-5000-8000-000000000002', 'mr', 'या स्क्रीनवरून WhatsApp करा, कॉल करा किंवा ईमेल पाठवा, किंवा तिकीट काढा आणि आम्ही ॲपमध्येच उत्तर देऊ. तिकिटात संपूर्ण संभाषण एकाच ठिकाणी राहते, म्हणून काहीही दोनदा सांगावे लागत नाही.'),

                    ('b1f0b000-0000-5000-8000-000000000001', 'en', 'Support replied'),
                    ('b1f0b000-0000-5000-8000-000000000001', 'hi', 'सहायता टीम ने जवाब दिया'),
                    ('b1f0b000-0000-5000-8000-000000000001', 'mr', 'सहाय्य टीमने उत्तर दिले'),
                    ('b1f0b000-0000-5000-8000-000000000002', 'en', 'Our team replied to your ticket. Tap to read the answer.'),
                    ('b1f0b000-0000-5000-8000-000000000002', 'hi', 'हमारी टीम ने आपके टिकट का जवाब दिया है। पढ़ने के लिए टैप करें।'),
                    ('b1f0b000-0000-5000-8000-000000000002', 'mr', 'आमच्या टीमने तुमच्या तिकिटाला उत्तर दिले आहे. वाचण्यासाठी टॅप करा.');
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // The values table cascades from the entries, so removing the seeded entries is enough.
            migrationBuilder.Sql("""
                DELETE FROM localization.localized_text_entries WHERE created_by = '8c1e5a42-77bd-4f0a-9a3e-2c6f1b7d4e91';
                """);
        }
    }
}
