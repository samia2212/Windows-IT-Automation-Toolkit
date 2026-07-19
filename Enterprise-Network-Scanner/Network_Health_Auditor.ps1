# ==========================================
# مشروع: نظام الفحص والتدقيق الموسع لشبكات الشركات (V2)
# المطور: سامية المالكي
# الوصف: فحص أجهزة متعددة في الشبكة، مراقبة تحديثات الويندوز، أعطال الطابعات، والأداء المتقدم
# ==========================================

# 1. تحديد مسار حفظ التقرير المركزي في المجلد المؤقت
$ReportPath = "$env:TEMP\Enterprise_Network_Report.html"

# 2. قائمة الأجهزة المستهدفة في الشبكة (يمكنك تعديل الأسماء هنا أو وضع IP لجهازك الحالي للتجربة)
# لتجربته محلياً على جهازك والأجهزة المحيطة يمكنك وضع اسم جهازك الحالي أو عناوين IP
$Computers = @($env:COMPUTERNAME) 

$TargetDevicesHTML = ""

# 3. حلقة تكرار للمرور على كافة الأجهزة وجمع بياناتها
foreach ($Computer in $Computers) {
    
    # أ) جلب تفاصيل مواصفات الجهاز المتقدمة والرقم التسلسلي
    $OS = (Get-WmiObject Win32_OperatingSystem -ComputerName $Computer).Caption
    $Model = (Get-WmiObject Win32_ComputerSystem -ComputerName $Computer).Model
    $SerialNumber = (Get-WmiObject Win32_BIOS -ComputerName $Computer).SerialNumber
    $RAM = [Math]::Round((Get-WmiObject Win32_ComputerSystem -ComputerName $Computer).TotalPhysicalMemory / 1GB, 2)

    # ب) فحص مساحة القرص C
    $DriveC = Get-WmiObject Win32_LogicalDisk -ComputerName $Computer -Filter "DeviceID='C:'"
    $FreeSpaceGB = [Math]::Round($DriveC.FreeSpace / 1GB, 2)
    $PercentFree = [Math]::Round(($DriveC.FreeSpace / $DriveC.Size) * 100, 2)
    $DiskColor = if ($PercentFree -lt 15) { "red" } else { "green" }

    # ج) فحص تحديثات الويندوز المعلقة (Windows Updates)
    $UpdateSession = New-Object -ComObject Microsoft.Update.Session
    $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
    $SearchResult = $UpdateSearcher.Search("IsInstalled=0 and Type='Software'")
    $PendingUpdatesCount = $SearchResult.Updates.Count
    $UpdateColor = if ($PendingUpdatesCount -gt 5) { "red" } else { "green" }

    # د) فحص مشاكل الطابعات المتصلة بالشبكة/الجهاز
    $PrinterProblems = Get-WmiObject Win32_Printer -ComputerName $Computer | Where-Object { $_.DetectedErrorState -ne 0 }
    $PrinterStatusText = "جميع الطابعات تعمل بشكل سليم"
    $PrinterColor = "green"
    if ($PrinterProblems) {
        $PrinterStatusText = "تم رصد مشكلة في طابعة: " + ($PrinterProblems | Select-Object -ExpandProperty Name)
        $PrinterColor = "red"
    }

    # هـ) جلب أكثر 10 عمليات استهلاكاً للذاكرة (RAM) لتدقيق الأداء
    $TopProcesses = Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10 | ForEach-Object {
        "<li><b>$($_.Name)</b> - ($([Math]::Round($_.WorkingSet / 1MB, 2)) MB)</li>"
    }

    # و) بناء صفحة التقرير الخاص بهذا الجهاز وتجميعها
    $TargetDevicesHTML += @"
    <div class="computer-section">
        <h2>🖥️ تقرير الجهاز: $Computer</h2>
        <div class="meta-info">
            <span><b>الموديل:</b> $Model</span>
            <span><b>الرقم التسلسلي:</b> $SerialNumber</span>
            <span><b>النظام:</b> $OS</span>
            <span><b>الذاكرة:</b> $RAM GB</span>
        </div>

        <div class="card $DiskColor">
            <div class="card-title">💾 مساحة القرص الصلب (C:)</div>
            <div>المساحة الحرة الحالية: <b>$FreeSpaceGB GB</b> (نسبة الفراغ: <b>$PercentFree %</b>)</div>
        </div>

        <div class="card $UpdateColor">
            <div class="card-title">🔄 تحديثات النظام المعلقة (Windows Updates)</div>
            <div>عدد التحديثات الأمنية بانتظار التثبيت: <b>$PendingUpdatesCount تحديثات</b></div>
        </div>

        <div class="card $PrinterColor">
            <div class="card-title">🖨️ حالة الطابعات المتصلة</div>
            <div>الوضع الحالي: <b>$PrinterStatusText</b></div>
        </div>

        <div class="card green">
            <div class="card-title">⚡ أعلى 10 عمليات استهلاكاً للذاكرة والأنشطة حالياً</div>
            <ul>$($TopProcesses -join "")</ul>
        </div>
    </div>
    <hr style="border: 1px solid #ddd; margin: 40px 0;">
"@
}

# 4. قالب الـ HTML الرئيسي للمشروع الموسع
$HTML_Template = @"
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <title>نظام التدقيق الموسع للبنية التحتية</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f0f3f6; color: #333; padding: 20px; }
        .container { max-width: 900px; margin: auto; background: white; padding: 30px; border-radius: 12px; box-shadow: 0 5px 20px rgba(0,0,0,0.08); }
        h1 { color: #2c3e50; text-align: center; border-bottom: 4px solid #2ecc71; padding-bottom: 15px; }
        h2 { color: #34495e; margin-top: 20px; }
        .meta-info { display: grid; grid-template-columns: repeat(2, 1fr); gap: 10px; background: #f8f9fa; padding: 15px; border-radius: 6px; margin-bottom: 20px; font-size: 14px; border: 1px solid #e9ecef; }
        .card { padding: 15px; border-radius: 6px; margin-bottom: 15px; border-right: 6px solid; }
        .green { border-right-color: #2ecc71; background-color: #f4fbf7; }
        .red { border-right-color: #e74c3c; background-color: #fdf4f4; }
        .card-title { font-weight: bold; margin-bottom: 5px; font-size: 15px; }
        ul { padding-right: 20px; margin: 5px 0; font-size: 14px; columns: 2; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 لوحة التدقيق المركزي لشبكة المنشأة (Enterprise IT Audit)</h1>
        $TargetDevicesHTML
        <p style="text-align: center; color: #95a5a6; font-size: 12px;">تم التوليد مركزيًا بواسطة سكربت إدارة الأنظمة والشبكات المتقدم.</p>
    </div>
</body>
</html>
"@

# 5. حفظ وفتح التقرير التفاعلي النهائي
$HTML_Template | Out-File -FilePath $ReportPath -Encoding utf8
Invoke-Item $ReportPath
