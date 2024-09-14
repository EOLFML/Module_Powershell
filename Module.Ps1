#########################################################################
#########################################################################
#########################################################################
##################### Script de Dretzer/EOLFML ##########################
#########################################################################
#########################################################################
#########################################################################

#Récupère les groupes d'un utilisateur 
function Get-ADGroupMemberOf
{
    param (
        [string]$User
    )

    $Groupe = (Get-ADUser $User -Properties memberof).memberof | Get-ADGroup | Select-Object name, Distinguishedname
    Return $Groupe
}

#Obtenir le TimeStamp
function Get-TimeStamp {
    param (
        $TimeStamp
    )
    [dateTime]::FromFileTimeutc($TimeStamp)
    return $DateTime
}

#Récupère les imprimantes de l'AD
function Get-ADPrinter {
    $ADs = Get-AdObject -Filter "objectCategory -eq 'printQueue'" -Prop *
    Return $ADs
}

#Fait un menu 
function Get-Menu {
    param (
        $Tableau
	    $Message="Veuillez sélectionner l'environnement souhaiter"
    )

    for($i=0; $i -lt $Tableau.Count;$i++)
    {
        Write-Host "$i = $($Tableau[$i])"
    }
    $Select = Read-Host $Message
    return $Tableau[$Select]
}

function Get-CIDR
{
    #Accepte deux paramètre l'ip et le CIDR sous forme ip = "10.128.1.1" et CIDR = 24 
    param (
        [string]$ip,
        [int]$CIDR
    )

    #Creation des variables utilisés 
    $FInip = $debutip = ""
    
    $split = $ip.Split(".")
    #Creation d'une variable objet qui stockera chaque octet séparément de l'ip
    $IPv4 = @{
        POctet = $split[0]
        DOctet = $split[1]
        TOctet = $split[2]
        QOctet = $split[3]
    }
    # Utilisation du modulo pour faire le calcul du masque 
    $Modulo = $CIDR%8
    $MASKFin = "1"*$Modulo + "0"*(8-$Modulo) 
    $MASKdebut = "0"*$Modulo + "1"*(8-$Modulo)
    
    # Si le CIDR est en dessous de 8 calcule   
    if ($CIDR -lt 8)
    {
        $Binaire = [System.Convert]::ToString($IPv4.POctet,2).PadLeft(8,'0')
        $strmask = [convert]::tostring([convert]::Touint32($MASKFin,2))
    }
    #Si le CIDR est supérieur à 8 alors récupérer le premier octet, transforme le second octet en binaire pour le calcule et gestion du masque
    if($CIDR -ge 8 )
    {
        $TabIP = $IPv4.POctet+"."
        $Binaire = [System.Convert]::ToString($IPv4.DOctet,2).PadLeft(8,'0')
        $strmask = "255."+[convert]::tostring([convert]::Touint32($MASKFin,2))
        # pareil qu'au dessus mais dans le cas ou c'est supérieur à 8
        if($CIDR -ge 16)
        {
            $TabIP += $IPv4.DOctet+"."
            $Binaire = [System.Convert]::ToString($IPv4.TOctet,2).PadLeft(8,'0')
            $strmask = "255.255." + [convert]::tostring([convert]::Touint32($MASKFin,2))
            if($CIDR -ge 24)
            {   
                $TabIP += $IPv4.TOctet+"."
                $Binaire = [System.Convert]::ToString($IPv4.QOctet,2).PadLeft(8,'0') 
                $strmask = "255.255.255." +[convert]::tostring([convert]::Touint32($MASKFin,2)) 
            }
                # gestion d'erreur en cas de mauvais CIDR (32) soit 255.255.255.255
	            if($CIDR -eq 32)
                {   
                    $TabIP += $IPv4.QOctet
                    $Binaire = [System.Convert]::ToString($IPv4.QOctet,2).PadLeft(8,'0') 
                    $strmask = "255.255.255.255"
                }
        }
    }
    # et logique et ou logique du CIDR avec l'ip et le masque
    foreach ($item in 0..($MaskFin.Length-1)) 
    {
        if(($Binaire[$item] -eq "1") -and ($MASKFin[$item] -eq "1"))
        {
            $debutip += "1"
        }if(($Binaire[$item] -eq "0") -or ($MASKFin[$item] -eq "0"))
        {
            $debutip += "0"
        }
        if(($Binaire[$item] -eq "0") -and ($MASKdebut[$item] -eq "0"))
        {
            $FinIp += "0"
        }if(($Binaire[$item] -eq "1") -or ($MASKdebut[$item] -eq "1"))
        {
            $FinIp += "1"
        }
    }
    # ReConversion binaire en décimal après les différents calcul ci-dessus
    $FInip = [System.Convert]::ToUInt32($FInip,2)
    $debutip = [System.Convert]::ToUInt32($debutip,2)
    
    # gestion du masque lorsque il est inférieur a 24 et supérieur a 24 + inférieur a 32
    if([math]::Round(($CIDR/8)) -eq 0)
    {
        $LastOctet =  [convert]::ToString($FInip) + (".255"* (3 - [math]::Round(($CIDR/8))))
        $StartOctet = [convert]::ToString($debutip) + (".0"* (3 - [math]::Round(($CIDR/8))))
        $strmask += (".0"* (3 - [math]::Round(($CIDR/8))))
    }elseif([math]::Round(($CIDR/8)) -lt 4) 
    {
        $LastOctet = $TabIP + $FInip + (".255"* (3 - [math]::Round(($CIDR/8))))
        $StartOctet = $TabIP + $debutip + (".0"* (3 - [math]::Round(($CIDR/8))))
        $strmask += (".0"* (3 - [math]::Round(($CIDR/8))))
    }elseif (([math]::Round(($CIDR/8)) -eq 4) -and ($CIDR -ne 32)) 
    {
        $LastOctet = $TabIP + $FInip 
        $StartOctet = $TabIP + $debutip
    }
    if($CIDR -eq 32)
    {
        $LastOctet = $StartOctet = $Binaire
        $strmask = "255.255.255.255" 
    }
    #retourne la variable objet network avec les différents informations
    $Network = @{
        "5. Fin" = $FInip - 1
        "6. Debut" = $debutip + 1
        "1. DebutPlage" = $StartOctet
        "2. FinPlage" = $LastOctet
        "8. Entrer" = $ip
        "3. CIDR" = $CIDR
        "4. MASK" = $strmask
        "7. TabIP" = $TabIP
    }
    return [System.Collections.SortedList]$Network
}

#Fonction permettant de réaliser une requete SNMPv1 acceptant deux paramètre (La communauté et l'ip) et renvoyant un objet
#Communauté sous forme "public" et ip "120.1.1.1"
Function Get-SNMPv1
{
    param(
        $Community,
        $OID ,
        $ip)
    #OID correspondant au hostname dans la plupart des systèmes
    #Cree une variable object permettant de faire des requetes SNMP
    $SNMP = New-Object -ComObject olePrn.OleSNMP 
    #Ouvre une connection SNMP avec ip et communauté
    $SNMP.open($ip,$Community,2,1000) 
    #Fait la requete SNMP pour obtenir le nom ou ecrit error dans la variable nom si impossible
    try
    { 
        $Nom = $SNMP.get($OID) 
    }
    catch 
    {
        Write-Error "Error"
        $nom  = "error"
    }
    #Retourne un object contenant deux information l'ip et le nom retourné si erreur retourne Error
    $RunResult = New-Object PSObject -Property @{
        ip=$ip
        Nom = $Nom
    }
    #Ferme la connexion SNMP
    $snmp.close()
    #Retourne la variable environnement
    Return $RunResult
}

#Fonction permettant de réaliser une requete SNMPv3. un seul paramètre d'entré accepter. Cependant il faut modifier le username ainsi que l'authtype & authsecret.
#Ne pas oublier de gerer l'OID pour obtenir les informations voulues.
Function Get-SNMPv3
{
    #paramètre à ameliorer, par exemple les différents clé SNMPv3
    # possibilité d'amélioration avec OID
   param($ip)
    #Ajoute le module SNMPv3 si l'utilisateur ne l'as pas
    if(((Get-InstalledModule -Name SNMPv3).Name).count -lt 1)
    {
        Install-Module -Name SNMPv3 -Scope CurrentUser -Force
    }

    $SNMP = $null
    #Request de base a modifier celon l'envie
    $GetRequest = @{
        UserName = ''
        OID      = '1.3.6.1.2.1.1.5.0'
        AuthType   = 'SHA1'
        AuthSecret = ''
    }
    # gestion d'erreur pour la requete SNMPv3
    try{$SNMP = Invoke-SNMPv3Get @GetRequest -Target $ip -ErrorAction SilentlyContinue}
    catch{
        $RunResult = New-Object PSObject -Property @{
            IP = $ip
            Nom = "error"}
        Write-Host "Erreur,$ip"
    }
    # si le SNMP n'as pas d'erreur alors 
    if($null -ne $SNMP)
    {
        $RunResult = New-Object PSObject -Property @{
        IP = $SNMP.Node
        Nom = $SNMP.Value}
    }
    Return $RunResult
}

#Permet de creer une variable environnement statique
function Set-EnvironnementVariable {
    param (
        $Variables,
        $Nom
    )
    [Environment]::SetEnvironmentVariable("$Nom",$Variables,'User')
    
}
#Permet de se connecter à VmWare grace au module CLI de vmware
function Get-ConnectionVmWare {
    #param ()
    $user = ""
    $pswd = ""
    $vCenterName = ''

    # Connects to a vSphere server by using the User and Password parameters.
    Connect-VIServer -Server $vcentername -Protocol https -User $user -Password $pswd    
}

#Permet de créer de nouvelles clés de registre.
function New-RegeditKey {
    param (
        $typeEmplacement = "HKCU:",
        $emplacement="",
        $Donnee = "",
        $TypeDonnee = "String",
        $Nom = "CoreLandscapeFileOnServer" 
    )
    $EmplacementReel = $typeEmplacement + $emplacement
    if (test-path "$EmplacementReel") {
        $Landscape = Get-Item "$EmplacementReel"
        if ($Landscape.Property -eq $Nom) {
            Set-Itemproperty -path "$EmplacementReel" -Name "$Nom" -value $Donnee
        }
        else {
            New-ItemProperty -Path "$EmplacementReel" -Name "$Nom" -Value $Donnee  -PropertyType $TypeDonnee
        }  
    }
    else {
        Set-Location $typeEmplacement
        New-Item -Name $emplacement -Force
        New-ItemProperty -Path "$EmplacementReel" -Name "$Nom" -Value $Donnee  -PropertyType $TypeDonnee
    }
}


function Convert-StringToSHA256 {
    Param (
        [Parameter(Mandatory=$true)]
        [string]
        $ClearString
    )
    
    $hasher = [System.Security.Cryptography.HashAlgorithm]::Create('sha256')
    $hash = $hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($ClearString))
    
    $hashString = [System.BitConverter]::ToString($hash)
    $hashString.Replace('-', '')
}

#Permet d'obtenir son adress ip public
function Get-NetworkIpPublic {
    Invoke-RestMethod -Uri http://whatismyip.akamai.com 
}

#Permet de savoir quels sont les anti virus de l'ordinateur
function Get-Antivirus {
    wmic /NAMESPACE:\\root\SecurityCenter2 PATH AntiVirusProduct GET /value
}