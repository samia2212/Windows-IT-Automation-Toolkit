# Windows IT Automation & Administration Toolkit 🛠️

مجموعة من السكربتات والأدوات البرمجية المؤتمتة لتسهيل مهام إدارة الأنظمة والدعم الفني في بيئات العمل.

---

## 📁 المشاريع الحالية (Current Tools)

### 1. نظام الفحص والصيانة الذاتية للأجهزة (Local IT Health Auditor)
* **المسار:** `Local-Health-Auditor/IT_Health_Check.ps1`
* **الوصف:** سكربت PowerShell محلي يقوم بفحص مؤشرات أداء النظام، المساحة التخزينية، والتدقيق الأمني وجدار الحماية، ثم توليد تقرير تفاعلي بصيغة HTML.

#### 🚀 طريقة التشغيل (How to Run):
1. افتح **PowerShell ISE** كمسؤول (Run as Administrator).
2. اسمح بتشغيل السكربتات عبر الأمر:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
