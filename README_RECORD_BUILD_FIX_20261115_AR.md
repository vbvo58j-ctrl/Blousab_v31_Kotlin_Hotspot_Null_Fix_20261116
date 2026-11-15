# بلوساب v30 — إصلاح فشل بناء التسجيل الصوتي (15 نوفمبر 2026)

## ما الذي ظهر؟
في صور سجل Klenocd IDE:
- `record_linux-0.7.2/lib/record_linux.dart:12:7`: الكلاس `RecordLinux` لا ينفذ `RecordMethodChannelPlatformInterface.startStream`.
- `record_linux-0.7.2/lib/record_linux.dart:36:16`: عدم توافق `hasPermission` مع واجهة `record_platform_interface-1.6.0`.
- `Target kernel_snapshot_program failed` و`assembleRelease failed` نتيجتان لهذين الخطأين.

## التصحيح داخل المشروع
- تحديث مجموعة الإضافات بشكل متوافق وبنسخ مثبتة: `record: 6.2.1` و`record_linux: 1.3.1` و`record_platform_interface: 1.6.0`.
- رفع الحد الأدنى لإصدار Dart إلى 3.5 ليتوافق مع `record` 6.x؛ تستخدم GitHub Actions في المشروع Flutter 3.47.2.
- إبقاء استخدام `AudioRecorder`, `RecordConfig`, `hasPermission`, `start`, `stop`, `dispose` كما هو، لأن هذه الواجهات مدعومة في إصدار `record` الجديد.
- إضافة `scripts/check_record_dependencies.py` لكشف الملف المقفل `pubspec.lock` إذا بقيت فيه إصدارات متضاربة، واستدعاؤه من الفحص الموحد وGitHub Actions.

## التشغيل عند Klenocd IDE / GitHub Actions
1. **استبدل مصدر المشروع بالكامل** بالحزمة المحدثة، وليس `pubspec.yaml` فقط.
2. إذا كان هناك `pubspec.lock` قديم، يلزم إعادة توليده باستخدام `flutter pub get` بعد تحديث `pubspec.yaml`. المشروع المرفق لا يتضمن lock قديمًا.
3. شغّل Build APK مجددًا. يقوم Workflow الحالي تلقائيًا بتشغيل `flutter pub get` ثم فحص توافق الإضافات ثم `flutter analyze` ثم `flutter test` وأخيرًا `flutter build apk --release`.
4. في Windows يمكن تشغيل `./RUN_ACCEPTANCE.ps1` من PowerShell، وفي Linux/Mac `bash RUN_ACCEPTANCE.sh`.

## نتائج التحقق في بيئة إعداد الحزمة
- جرى التحقق من صور الخطأ ومن إصدارات الحزم المنشورة، وتشغيل اختبارات المصدر المحلية.
- لم يتوفر Flutter SDK في بيئة إعداد الحزمة؛ لم يُنفذ `flutter pub get` أو `flutter build apk` هنا. نجاح البناء الفعلي غير مؤكد حتى تنفيذ Workflow.
- موانع الأمان الإنتاجية السابقة (خصوصًا التشفير الطرفي) **لم تُحل ضمن هذا الإصلاح**.
