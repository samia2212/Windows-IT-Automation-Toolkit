# ==========================================
# مشروع: سكربت الفحص والصيانة الذاتية للأجهزة
# المطور: سامية المالكي]
# الوصف: فحص صحة النظام، المساحة، الأمان، والشبكة وتوليد تقرير HTML متميز
# ==========================================

# 1. تحديد مسار حفظ التقرير في المجلد المؤقت للجهاز (مسار مضمون 100%)
$ReportPath = "$env:TEMP\IT_Health_Report.html"

# 2. جمع معلومات النظام الأساسية
$ComputerName = $env:COMPUTERNAME
$OS = (Get-WmiObject Win32_OperatingSystem).Caption
$RAM = [Math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)

# 3. فحص مساحة القرص C
$DriveC = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
$FreeSpaceGB = [Math]::Round($DriveC.FreeSpace / 1GB, 2)
$TotalSpaceGB = [Math]::Round($DriveC.Size / 1GB, 2)
$PercentFree = [Math]::Round(($DriveC.FreeSpace / $DriveC.Size) * 100, 2)

# تحديد لون التنبيه للمساحة (أحمر إذا كانت أقل من 15%)
$DiskStatusColor = "green"
if ($PercentFree -lt 15) { $DiskStatusColor = "red" }

# 4. فحص جدار الحماية (Firewall)
$FirewallProfile = Get-NetFirewallProfile -Profile Domain,Private,Public
$FirewallStatus = "مفعّل"
$FirewallColor = "green"

foreach ($profile in $FirewallProfile) {
    if ($profile.Enabled -eq $false) {
        $FirewallStatus = "غير مفعّل بالكامل! (خطر أمني)"
        $FirewallColor = "red"
        break
    }
}

# 5. فحص الاتصال بالإنترنت (Ping Test)
$InternetStatus = "متصل"
$InternetColor = "green"
if (-not (Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet)) {
    $InternetStatus = "غير متصل بالإنترنت"
    $InternetColor = "red"
}

# 6. جلب أكثر 3 عمليات استهلاكاً للذاكرة (RAM)
$TopProcesses = Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 3 | ForEach-Object {
    "<li><b>$($_.Name)</b> - استهلاك الذاكرة: $([Math]::Round($_.WorkingSet / 1MB, 2)) MB</li>"
}

# 7. بناء التقرير بصيغة HTML مدمج معها كود CSS للتنسيق الجمالي
$HTML_Template = @"
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <title>تقرير فحص النظام الدوري</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f6f9; color: #333; padding: 20px; }
        .container { max-width: 800px; margin: auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; font-size: 24px; }
        .meta-info { display: flex; justify-content: space-between; background: #ecf0f1; padding: 10px 15px; border-radius: 5px; margin-bottom: 20px; font-size: 14px; }
        .card { padding: 15px; border-radius: 5px; margin-bottom: 15px; border-right: 5px solid; }
        .green { border-right-color: #2ecc71; background-color: #ebfaf0; }
        .red { border-right-color: #e74c3c; background-color: #fdf2f2; }
        .card-title { font-weight: bold; font-size: 16px; margin-bottom: 5px; }
        ul { padding-right: 20px; margin: 5px 0 0 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>تقرير الفحص الدوري لسلامة الجهاز 🛠️</h1>
        
        <div class="meta-info">
            <span><b>اسم الجهاز:</b> $ComputerName</span>
            <span><b>نظام التشغيل:</b> $OS</span>
            <span><b>حجم الذاكرة الكلي:</b> $RAM GB</span>
        </div>

        <div class="card $DiskStatusColor">
            <div class="card-title">💾 مساحة القرص الصلب (C:)</div>
            <div>المساحة المتبقية: <b>$FreeSpaceGB GB</b> من أصل $TotalSpaceGB GB (نسبة المساحة الفارغة: <b>$PercentFree %</b>)</div>
        </div>

        <div class="card $FirewallColor">
            <div class="card-title">🛡️ حالة جدار الحماية (Firewall)</div>
            <div>حالة الأمان الحالية: <b>$FirewallStatus</b></div>
        </div>

        <div class="card $InternetColor">
            <div class="card-title">🌐 اختبار الاتصال بالإنترنت</div>
            <div>حالة الشبكة: <b>$InternetStatus</b></div>
        </div>

        <div class="card green">
            <div class="card-title">⚡ العمليات الأكثر استهلاكاً للذاكرة (Top 3 Processes)</div>
            <ul>
                $($TopProcesses -join "")
            </ul>
        </div>

        <p style="text-align: center; color: #7f8c8d; font-size: 12px; margin-top: 30px;">تم توليد هذا التقرير تلقائياً بواسطة سكربت PowerShell الذكي.</p>
    </div>
</body>
</html>
"@

# 8. حفظ الملف وفتحه تلقائياً للمستخدم ليرى النتيجة فوراً
$HTML_Template | Out-File -FilePath $ReportPath -Encoding utf8
Invoke-Item $ReportPath


