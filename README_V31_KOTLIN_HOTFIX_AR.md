# بلوساب v31 — إصلاح فشل Kotlin في Klenocd IDE

## العطل من الصورة

`MainActivity.kt` السطران 506 و507: `Only safe (?.) or non-null asserted (!!.) calls are allowed on a nullable receiver of type WifiConfiguration?`.

## السبب

في أنظمة أندرويد الأقدم، `reservation.wifiConfiguration` تُرجع كائنًا قد يكون `null`، بينما الكود كان يصل إلى `SSID` و`preSharedKey` دون التحقق.

## الإصلاح

- التحقق من `legacy == null` أولًا، ثم قراءة القيم بأمان.
- إذا لم يوفر أندرويد إعدادات الشبكة، تُغلَق نقطة الاتصال ويُعاد خطأ `LOCAL_HOTSPOT_CONFIGURATION` من دون انهيار.
- أبقينا معالجة `softApConfiguration` لأندرويد 11 وما فوق دون تعديل.
- أُضيف فحص رجوع `scripts/check_v31_hotspot_kotlin.py` إلى اختبارات القبول وGitHub Actions.

## التحقق

فحص مصدر Kotlin فقط؛ **لم نتمكن من إجراء بناء APK حقيقي** لعدم توفر Flutter SDK/Android SDK في بيئة التنفيذ. نجاح الفحوص الساكنة لا يضمن خلو البناء من أخطاء أخرى أو عمل نقطة الاتصال على كل جهاز.

## الأمر على Windows

من مجلد المشروع: `powershell -ExecutionPolicy Bypass -File .\RUN_ACCEPTANCE.ps1`.

فحص الأمان الإنتاجي (عدم اكتمال التشفير الطرفي) منفصل عن إصلاح هذا الخطأ، وما يزال غير مغلق.
