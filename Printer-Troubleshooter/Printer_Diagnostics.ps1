# ==========================================
# مشروع: مدقق ومصحي أخطاء الطابعات الذكي (Printer Troubleshooter & Auditor)
# الوصف: فحص شامل لكافة الطابعات، اكتشاف نوع المشكلة بدقة، وتقديم خطة الحل الفورية
# ==========================================

$ReportPath = "$env:TEMP\Printer_Diagnostics_Report.html"

# 1. معلومات الجهاز والوقت
$ComputerName = $env:COMPUTERNAME
$ScanTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# 2. فحص خدمة Print Spooler المسؤولة عن الطباعة في ويندوز
$SpoolerService = Get-Service -Name "Spooler"
$SpoolerStatusText = if ($SpoolerService.Status -eq 'Running') { "مفعّلة وتعمل بنجاح ✅" } else { "🚨 متوقفة! (وهذا يسبب عدم استجابة كافة الطابعات)" }
$SpoolerColor = if ($SpoolerService.Status -eq 'Running') { "green" } else { "red" }

# 3. جلب جميع الطابعات المتصلة بالجهاز/الشبكة وتحليل أخطائها
$Printers = Get-WmiObject Win32_Printer
$PrinterReportHTML = ""

foreach ($Printer in $Printers) {
    
    $PrinterName = $Printer.Name
    $PortName = $Printer.PortName
    $IsDefault = if ($Printer.Default) { "نعم (الطابعة الافتراضية)" } else { "لا" }
    
    # تحديد نوع الاتصال (شبكة أو USB)
    $ConnectionType = if ($PortName -like "*SEC*" -or $PortName -like "*192.*" -or $PortName -like "*10.*" -or $PortName -like "*LAN*") { "طابعة شبكة (Network Printer 🌐)" } else { "طابعة محلية (USB / Local 🔌)" }

    # تحليل حالة الطابعة واكتشاف المشكلة وحلها
    $Status = $Printer.PrinterStatus
    $DetectedError = $Printer.DetectedErrorState
    
    $IssueTitle = "لا توجد أخطاء ظاهرية"
    $ProblemDetails = "الطابعة جاهزة للاستخدام ومستجيبة للأوامر."
    $SolutionSteps = "لا يتطلب أي إجراء حالياً."
    $CardColor = "green"

    # تحليل المشاكل الشائعة والمتقدمة بناءً على رموز WMI للأخطاء
    if ($Printer.WorkOffline -eq $true) {
        $IssueTitle = "🚨 الطابعة في وضع Off-Line (غير متصلة)"
        $ProblemDetails = "النظام يعرض الطابعة كـ Offline إما لقطع الكيبل، أو إيقاف تشغيل الطابعة، أو تعليق الإعداد."
        $SolutionSteps = "1. التأكد من تشغيل الطابعة وتوصيل الكيبل/الشبكة.<br>2. فتح 'Printers & Scanners' وإلغاء خيار 'Use Printer Offline'."
        $CardColor = "red"
    }
    elseif ($DetectedError -eq 3) {
        $IssueTitle = "⚠️ انحشار الورق (Paper Jam)"
        $ProblemDetails = "تم رصد انسداد أو علوق ورق داخل بكرات السحب الخاصة بالطابعة."
        $SolutionSteps = "1. إيقاف تشغيل الطابعة وفتح الغطاء الخلفي/العلوي.<br>2. إزالة الورق العالق برفق باتجاه حركة البكرات ثم إعادة التشغيل."
        $CardColor = "red"
    }
    elseif ($DetectedError -eq 4) {
        $IssueTitle = "⚠️ نفاد الورق (Out of Paper)"
        $ProblemDetails = "درج التغذية بالورق فارغ تماماً أو غير مثبت بشكل صحيح."
        $SolutionSteps = "قم بتعبئة الورق في الدرج المخصص والتأكد من إغلاقه بإحكام."
        $CardColor = "red"
    }
    elseif ($DetectedError -eq 5) {
        $IssueTitle = "🚨 نفاد الحبر / التونر (Toner/Ink Low or Empty)"
        $ProblemDetails = "مستوى الحبر منخفض جداً أو العلبة غير معرّفة بالشكل الصحيح."
        $SolutionSteps = "استبدال خرطوشة الحبر (Toner/Ink Cartridge) أو إعادة تركيبها لتنظيف الشريحة الإلكترونية."
        $CardColor = "red"
    }
    elseif ($DetectedError -eq 9 -or $Status -eq 7) {
        $IssueTitle = "🚨 خطأ في تعريف الطابعة أو الاتصال (Driver / Offline Error)"
        $ProblemDetails = "تعذر الوصول للطابعة عبر المنفذ المحدد ($PortName)."
        $SolutionSteps = "1. عمل Ping على IP الطابعة للتأكد من وصول الشبكة.<br>2. إعادة تثبيت تعريف الطابعة (Driver Update)."
        $CardColor = "red"
    }

    # بناء كرت التقرير الخاص بكل طابعة
    $PrinterReportHTML += @"
    <div class="card $CardColor">
        <div class="card-title">🖨️ اسم الطابعة: $PrinterName</div>
        <div style="margin: 8px 0; font-size: 13px;">
            <b>نوع الاتصال:</b> $ConnectionType | <b>المنفذ:</b> $PortName | <b>افتراضية:</b> $IsDefault
        </div>
        <hr style="border: 0.5px solid #ddd; margin: 8px 0;">
        <div><b>🔍 المشكلة المكتشفة:</b> <span style="color: #c0392b; font-weight: bold;">$IssueTitle</span></div>
        <div style="margin-top: 4px;"><b>📝 التفاصيل:</b> $ProblemDetails</div>
        <div class="solution-box">
            <b>🛠️ كيفية الحل والمهام المطلوبة:</b><br>
            $SolutionSteps
        </div>
    </div>
"@
}

# 4. بناء تقرير الـ HTML التفاعلي
$HTML_Template = @"
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <title>تقرير تشخيص وإصلاح الطابعات الشامل</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f6f9; color: #333; padding: 20px; }
        .container { max-width: 850px; margin: auto; background: white; padding: 30px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
        h1 { color: #2c3e50; text-align: center; border-bottom: 4px solid #3498db; padding-bottom: 12px; }
        .meta-info { display: flex; justify-content: space-between; background: #eef2f5; padding: 12px; border-radius: 6px; font-size: 14px; margin-bottom: 20px; }
        .card { padding: 18px; border-radius: 8px; margin-bottom: 20px; border-right: 6px solid; font-size: 14px; }
        .green { border-right-color: #2ecc71; background-color: #f1faf4; }
        .red { border-right-color: #e74c3c; background-color: #fdf3f3; }
        .card-title { font-weight: bold; font-size: 16px; color: #2c3e50; }
        .solution-box { background: white; padding: 10px 15px; border-radius: 6px; margin-top: 10px; border: 1px solid #e0e0e0; font-size: 13px; line-height: 1.6; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 لوحة تشخيص وحلول أخطاء الطابعات (Printer Diagnostics)</h1>
        
        <div class="meta-info">
            <span><b>اسم الجهاز:</b> $ComputerName</span>
            <span><b>وقت الفحص:</b> $ScanTime</span>
        </div>

        <!-- كرت خدمة الطباعة Spooler -->
        <div class="card $SpoolerColor">
            <div class="card-title">⚙️ خدمة نظام الطباعة الرئيسي (Print Spooler Service)</div>
            <div>حالة الخدمة: <b>$SpoolerStatusText</b></div>
            if ($SpoolerService.Status -ne 'Running') {
                <div class="solution-box"><b>🛠️ خطوة الحل:</b> افتح PowerShell كمسؤول ونفذ الأمر: <code>Start-Service Spooler</code> لتشغيل الخدمة فوراً.</div>
            }
        </div>

        <h2 style="color: #34495e; font-size: 18px; margin-top: 25px;">🖨️ قائمة الطابعات وحالتها التشغيلية:</h2>
        $PrinterReportHTML

        <p style="text-align: center; color: #bdc3c7; font-size: 11px; margin-top: 30px;">تم التوليد تلقائياً عبر سكربت أتمتة الدعم الفني لحل مشاكل الطابعات.</p>
    </div>
</body>
</html>
"@

$HTML_Template | Out-File -FilePath $ReportPath -Encoding utf8
Invoke-Item $ReportPath
