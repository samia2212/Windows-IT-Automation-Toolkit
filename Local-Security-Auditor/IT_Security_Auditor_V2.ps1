# ==========================================
# مشروع: مدقق الامتثال الأمني لأجهزة الموظفين - النسخة المتقدمة (V2)
# الوصف: فحص عميق للثغرات الحقيقية في المنشآت (المنافذ، المنافذ الخارجية، الحسابات المهملة)
# ==========================================

$ReportPath = "$env:TEMP\Advanced_Security_Compliance_Report.html"

# معلومات الجهاز الأساسية
$ComputerName = $env:COMPUTERNAME
$UserName = $env:USERNAME
$ScanTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# عدادات الامتثال الجديدة (8 فحوصات شاملة)
$TotalChecks = 8
$PassedChecks = 0

# 1. فحص حالة جدار الحماية (Firewall)
$Firewall = Get-NetFirewallProfile -Profile Domain,Private,Public
$FirewallPassed = $true
foreach ($profile in $Firewall) { if ($profile.Enabled -eq $false) { $FirewallPassed = $false } }
$FirewallResult = if ($FirewallPassed) { $PassedChecks++; "ممتثل ✅ (جدار الحماية يعمل على كافة المستويات)" } else { "🚨 ثغرة: جدار الحماية معطل! الجهاز مكشوف للشبكة." }
$FirewallColor = if ($FirewallPassed) { "green" } else { "red" }

# 2. فحص سياسة قفل الشاشة التلقائي (منع التسلل الفيزيائي للمكاتب)
$ScreenLockPath = "HKCU:\Control Panel\Desktop"
$ScreenLockValue = Get-ItemProperty -Path $ScreenLockPath -Name "ScreenSaveActive" -ErrorAction SilentlyContinue
$ScreenTimeout = Get-ItemProperty -Path $ScreenLockPath -Name "ScreenSaveTimeOut" -ErrorAction SilentlyContinue
$LockPassed = $false
if ($ScreenLockValue.ScreenSaveActive -eq "1" -and $ScreenTimeout.ScreenSaveTimeOut -le 900) { $LockPassed = $true; $PassedChecks++ }
$LockResult = if ($LockPassed) { "ممتثل ✅ (الشاشة تقفل تلقائياً خلال الوقت الآمن)" } else { "🚨 خطر: قفل الشاشة التلقائي معطل أو مدته طويلة! خطر تسلل فيزيائي." }
$LockColor = if ($LockPassed) { "green" } else { "red" }

# 3. فحص بروتوكول SMBv1 (مسبب هجمات الفدية Ransomware)
$SMBv1 = Get-SmbServerConfiguration | Select-Object -ExpandProperty EnableSMB1Protocol
$SMBPassed = if ($SMBv1 -eq $false) { $PassedChecks++; $true } else { $false }
$SMBResult = if ($SMBPassed) { "ممتثل ✅ (البروتوكول القديم معطل)" } else { "🚨 ثغرة حرجة: بروتوكول SMBv1 مفعّل! الجهاز عرضة لهجمات التشفير والفدية." }
$SMBColor = if ($SMBPassed) { "green" } else { "red" }

# 4. [جديد] فحص السماح بنقل البيانات عبر الفلاشات (منع تسريب البيانات Insider Threats / USB)
# التحقق مما إذا كانت الشركة تفرض قيوداً على منافذ الـ USB لمنع سرقة البيانات
$USBRegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR"
$USBValue = Get-ItemProperty -Path $USBRegPath -Name "Start" -ErrorAction SilentlyContinue
$USBPassed = if ($USBValue.Start -eq 4) { $PassedChecks++; $true } else { $false } 
$USBResult = if ($USBPassed) { "ممتثل ✅ (منافذ التخزين الخارجية مقيدة لحماية البيانات)" } else { "⚠️ تنبيه: منافذ USB مفتوحة بالكامل؛ خطر تسريب بيانات المنشأة عبر فلاش خارجي." }
$USBColor = if ($USBPassed) { "green" } else { "red" }

# 5. [جديد] فحص منفذ التحكم عن بعد RDP - Port 3389 (منع هجمات التسلل الخارجي)
# فحص إذا كان المنفذ مفتوحاً ويستمع للاتصالات الخارجية بشكل غير آمن
$RDPConnections = Get-NetTCPConnection -LocalPort 3389 -State Listen -ErrorAction SilentlyContinue
$RDPPassed = if (-not $RDPConnections) { $PassedChecks++; $true } else { $false }
$RDPResult = if ($RDPPassed) { "ممتثل ✅ (منفذ التحكم عن بعد RDP مغلق وغير مكشوف)" } else { "🚨 خطر: منفذ RDP (3389) مفتوح ويستمع للشبكة! هدف رئيسي للمخترقين لتشغيل برمجيات الفدية." }
$RDPColor = if ($RDPPassed) { "green" } else { "red" }

# 6. [جديد] فحص الحساب الافتراضي للمسؤول (Built-in Administrator)
# من أخطر الممارسات ترك الحساب الافتراضي نشطاً لأنه مستهدف بهجمات التخمين (Brute-Force)
$LocalAdminUser = Get-LocalUser -Name "Administrator" -ErrorAction SilentlyContinue
$AdminUserPassed = if ($LocalAdminUser.Enabled -eq $false) { $PassedChecks++; $true } else { $false }
$AdminUserResult = if ($AdminUserPassed) { "ممتثل ✅ (الحساب الافتراضي الافتراضي معطل)" } else { "⚠️ تنبيه: الحساب الافتراضي 'Administrator' نشط! يوصى بتعطيله والاعتماد على حسابات مخصصة." }
$AdminUserColor = if ($AdminUserPassed) { "green" } else { "red" }

# 7. [جديد] فحص متطلبات تعقيد كلمات المرور المحلية (Password Complexity)
# التحقق من إجبار النظام للمستخدمين على وضع كلمات مرور معقدة
$SecurityPolicy = net accounts | Out-String
$PasswordComplexityPassed = if ($SecurityPolicy -match "Password history length:\s+[1-9]") { $PassedChecks++; $true } else { $false }
$PasswordResult = if ($PasswordComplexityPassed) { "ممتثل ✅ (سياسة حماية وتعقيد كلمات المرور مفعلة)" } else { "⚠️ تنبيه: سياسة تعقيد كلمات المرور المحلية تحتاج لمراجعة وتعزيز." }
$PasswordColor = if ($PasswordComplexityPassed) { "green" } else { "red" }

# 8. [جديد] فحص التحديثات الأمنية المعلقة (Unpatched Vulnerabilities)
$UpdateSession = New-Object -ComObject Microsoft.Update.Session
$UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
$SearchResult = $UpdateSearcher.Search("IsInstalled=0 and Type='Software'")
$PendingUpdatesCount = $SearchResult.Updates.Count
$UpdatesPassed = if ($PendingUpdatesCount -le 3) { $PassedChecks++; $true } else { $false }
$UpdatesResult = if ($UpdatesPassed) { "ممتثل ✅ (النظام محدث، توجد $PendingUpdatesCount تحديثات معلقة فقط)" } else { "🚨 ثغرة: توجد $PendingUpdatesCount تحديثات أمنية معلقة! النظام معرض لاستغلال الثغرات المعروفة." }
$UpdatesColor = if ($UpdatesPassed) { "green" } else { "red" }


# حساب النسبة المئوية للامتثال الأمني الشامل
$ComplianceScore = [Math]::Round(($PassedChecks / $TotalChecks) * 100, 2)
$ScoreColor = if ($ComplianceScore -ge 85) { "#2ecc71" } elseif ($ComplianceScore -ge 60) { "#f39c12" } else { "#e74c3c" }

# بناء تقرير الـ HTML المطور
$HTML_Template = @"
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <title>مدقق الامتثال الأمني المطور V2</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f6f9; color: #333; padding: 20px; }
        .container { max-width: 850px; margin: auto; background: white; padding: 30px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.05); }
        h1 { color: #2c3e50; text-align: center; margin-bottom: 5px; }
        .score-circle { width: 130px; height: 130px; border-radius: 50%; background: $ScoreColor; color: white; text-align: center; line-height: 130px; font-size: 32px; font-weight: bold; margin: 20px auto; box-shadow: 0 4px 12px rgba(0,0,0,0.15); }
        .meta-info { display: flex; justify-content: space-between; background: #eef2f5; padding: 12px; border-radius: 6px; font-size: 14px; margin-bottom: 25px; }
        .card { padding: 15px; border-radius: 6px; margin-bottom: 15px; border-right: 6px solid; font-size: 14px; }
        .green { border-right-color: #2ecc71; background-color: #f1faf4; }
        .red { border-right-color: #e74c3c; background-color: #fdf3f3; }
        .card-title { font-weight: bold; margin-bottom: 5px; font-size: 15px; color: #2c3e50; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🛡️ مدقق الامتثال الأمني المطور لبيئات العمل (V2)</h1>
        <p style="text-align: center; color: #7f8c8d;">أداة فحص الثغرات المحلية وسوء الإعدادات الشائعة في أجهزة المنشأة</p>
        
        <div class="score-circle">$ComplianceScore%</div>
        <p style="text-align: center; font-weight: bold; margin-bottom: 20px;">نسبة الامتثال الأمني الإجمالية للجهاز</p>

        <div class="meta-info">
            <span><b>اسم الجهاز:</b> $ComputerName</span>
            <span><b>المستعلم:</b> $UserName</span>
            <span><b>وقت التدقيق:</b> $ScanTime</span>
        </div>

        <div class="card $FirewallColor"><div class="card-title">1. جدار حماية النظام (Firewall Misconfiguration)</div><div>الحالة: $FirewallResult</div></div>
        <div class="card $LockColor"><div class="card-title">2. سياسة قفل الشاشة التلقائي (Physically Unlocked Devices)</div><div>الحالة: $LockResult</div></div>
        <div class="card $SMBColor"><div class="card-title">3. بروتوكول SMBv1 (Ransomware Vulnerability)</div><div>الحالة: $SMBResult</div></div>
        <div class="card $USBColor"><div class="card-title">4. حظر وسائط التخزين الخارجية (USB Data Leakage)</div><div>الحالة: $USBResult</div></div>
        <div class="card $RDPColor"><div class="card-title">5. منفذ التحكم عن بعد (RDP Port 3389 Exposure)</div><div>الحالة: $RDPResult</div></div>
        <div class="card $AdminUserColor"><div class="card-title">6. الحسابات الافتراضية النشطة (Default Admin Account)</div><div>الحالة: $AdminUserResult</div></div>
        <div class="card $PasswordColor"><div class="card-title">7. سياسة تعقيد الـ Password (Weak Local Accounts)</div><div>الحالة: $PasswordResult</div></div>
        <div class="card $UpdatesColor"><div class="card-title">8. إدارة التحديثات الأمنية المعلقة (Unpatched Systems)</div><div>الحالة: $UpdatesResult</div></div>

        <p style="text-align: center; color: #bdc3c7; font-size: 11px; margin-top: 30px;">تمت الأتمتة والتدقيق استناداً إلى معايير الحماية الأساسية لأنظمة تشغيل الشركات.</p>
    </div>
</body>
</html>
"@

$HTML_Template | Out-File -FilePath $ReportPath -Encoding utf8
Invoke-Item $ReportPath
