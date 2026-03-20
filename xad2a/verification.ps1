Add-Type -AssemblyName System.Windows.Forms
$f = New-Object Windows.Forms.Form
$f.Text = 'Verification'
$f.Size = New-Object System.Drawing.Size(300, 150)
$f.StartPosition = 'CenterScreen'
$f.MaximizeBox = $false
$f.FormBorderStyle = 'FixedDialog'

$b = New-Object Windows.Forms.Button
$b.Text = 'CLICK HERE TO VERIFY ✅'
$b.Dock = 'Fill'
$b.BackColor = 'LightGreen'
$b.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)

$b.Add_Click({$f.Close()})
$f.Controls.Add($b)

$f.ShowDialog()
