function Get-HtmlColorCodes {
    <#
    .SYNOPSIS
        Shows all HTML named color codes from https://htmlcolorcodes.com/color-names/

    .DESCRIPTION
        Displays all 140 standard CSS/HTML named colors with their hex codes and RGB values.
        Colors are grouped by color family for easy browsing.

    .PARAMETER Filter
        Optional string to filter color names (case-insensitive)

    .EXAMPLE
        Get-HtmlColorCodes
        Shows all 140 HTML named colors

    .EXAMPLE
        Get-HtmlColorCodes -Filter "blue"
        Shows only color names containing "blue"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Filter = ""
    )

    $htmlColors = @(
        # Reds
        [PSCustomObject]@{ Name = "IndianRed";            Hex = "#CD5C5C"; R = 205; G = 92;  B = 92  }
        [PSCustomObject]@{ Name = "LightCoral";           Hex = "#F08080"; R = 240; G = 128; B = 128 }
        [PSCustomObject]@{ Name = "Salmon";               Hex = "#FA8072"; R = 250; G = 128; B = 114 }
        [PSCustomObject]@{ Name = "DarkSalmon";           Hex = "#E9967A"; R = 233; G = 150; B = 122 }
        [PSCustomObject]@{ Name = "LightSalmon";          Hex = "#FFA07A"; R = 255; G = 160; B = 122 }
        [PSCustomObject]@{ Name = "Crimson";              Hex = "#DC143C"; R = 220; G = 20;  B = 60  }
        [PSCustomObject]@{ Name = "Red";                  Hex = "#FF0000"; R = 255; G = 0;   B = 0   }
        [PSCustomObject]@{ Name = "FireBrick";            Hex = "#B22222"; R = 178; G = 34;  B = 34  }
        [PSCustomObject]@{ Name = "DarkRed";              Hex = "#8B0000"; R = 139; G = 0;   B = 0   }
        # Pinks
        [PSCustomObject]@{ Name = "Pink";                 Hex = "#FFC0CB"; R = 255; G = 192; B = 203 }
        [PSCustomObject]@{ Name = "LightPink";            Hex = "#FFB6C1"; R = 255; G = 182; B = 193 }
        [PSCustomObject]@{ Name = "HotPink";              Hex = "#FF69B4"; R = 255; G = 105; B = 180 }
        [PSCustomObject]@{ Name = "DeepPink";             Hex = "#FF1493"; R = 255; G = 20;  B = 147 }
        [PSCustomObject]@{ Name = "MediumVioletRed";      Hex = "#C71585"; R = 199; G = 21;  B = 133 }
        [PSCustomObject]@{ Name = "PaleVioletRed";        Hex = "#DB7093"; R = 219; G = 112; B = 147 }
        # Oranges
        [PSCustomObject]@{ Name = "Coral";                Hex = "#FF7F50"; R = 255; G = 127; B = 80  }
        [PSCustomObject]@{ Name = "Tomato";               Hex = "#FF6347"; R = 255; G = 99;  B = 71  }
        [PSCustomObject]@{ Name = "OrangeRed";            Hex = "#FF4500"; R = 255; G = 69;  B = 0   }
        [PSCustomObject]@{ Name = "DarkOrange";           Hex = "#FF8C00"; R = 255; G = 140; B = 0   }
        [PSCustomObject]@{ Name = "Orange";               Hex = "#FFA500"; R = 255; G = 165; B = 0   }
        # Yellows
        [PSCustomObject]@{ Name = "Gold";                 Hex = "#FFD700"; R = 255; G = 215; B = 0   }
        [PSCustomObject]@{ Name = "Yellow";               Hex = "#FFFF00"; R = 255; G = 255; B = 0   }
        [PSCustomObject]@{ Name = "LightYellow";          Hex = "#FFFFE0"; R = 255; G = 255; B = 224 }
        [PSCustomObject]@{ Name = "LemonChiffon";         Hex = "#FFFACD"; R = 255; G = 250; B = 205 }
        [PSCustomObject]@{ Name = "LightGoldenrodYellow"; Hex = "#FAFAD2"; R = 250; G = 250; B = 210 }
        [PSCustomObject]@{ Name = "PapayaWhip";           Hex = "#FFEFD5"; R = 255; G = 239; B = 213 }
        [PSCustomObject]@{ Name = "Moccasin";             Hex = "#FFE4B5"; R = 255; G = 228; B = 181 }
        [PSCustomObject]@{ Name = "PeachPuff";            Hex = "#FFDAB9"; R = 255; G = 218; B = 185 }
        [PSCustomObject]@{ Name = "PaleGoldenrod";        Hex = "#EEE8AA"; R = 238; G = 232; B = 170 }
        [PSCustomObject]@{ Name = "Khaki";                Hex = "#F0E68C"; R = 240; G = 230; B = 140 }
        [PSCustomObject]@{ Name = "DarkKhaki";            Hex = "#BDB76B"; R = 189; G = 183; B = 107 }
        # Purples
        [PSCustomObject]@{ Name = "Lavender";             Hex = "#E6E6FA"; R = 230; G = 230; B = 250 }
        [PSCustomObject]@{ Name = "Thistle";              Hex = "#D8BFD8"; R = 216; G = 191; B = 216 }
        [PSCustomObject]@{ Name = "Plum";                 Hex = "#DDA0DD"; R = 221; G = 160; B = 221 }
        [PSCustomObject]@{ Name = "Violet";               Hex = "#EE82EE"; R = 238; G = 130; B = 238 }
        [PSCustomObject]@{ Name = "Orchid";               Hex = "#DA70D6"; R = 218; G = 112; B = 214 }
        [PSCustomObject]@{ Name = "Fuchsia";              Hex = "#FF00FF"; R = 255; G = 0;   B = 255 }
        [PSCustomObject]@{ Name = "Magenta";              Hex = "#FF00FF"; R = 255; G = 0;   B = 255 }
        [PSCustomObject]@{ Name = "MediumOrchid";         Hex = "#BA55D3"; R = 186; G = 85;  B = 211 }
        [PSCustomObject]@{ Name = "MediumPurple";         Hex = "#9370DB"; R = 147; G = 112; B = 219 }
        [PSCustomObject]@{ Name = "RebeccaPurple";        Hex = "#663399"; R = 102; G = 51;  B = 153 }
        [PSCustomObject]@{ Name = "BlueViolet";           Hex = "#8A2BE2"; R = 138; G = 43;  B = 226 }
        [PSCustomObject]@{ Name = "DarkViolet";           Hex = "#9400D3"; R = 148; G = 0;   B = 211 }
        [PSCustomObject]@{ Name = "DarkOrchid";           Hex = "#9932CC"; R = 153; G = 50;  B = 204 }
        [PSCustomObject]@{ Name = "DarkMagenta";          Hex = "#8B008B"; R = 139; G = 0;   B = 139 }
        [PSCustomObject]@{ Name = "Purple";               Hex = "#800080"; R = 128; G = 0;   B = 128 }
        [PSCustomObject]@{ Name = "Indigo";               Hex = "#4B0082"; R = 75;  G = 0;   B = 130 }
        [PSCustomObject]@{ Name = "SlateBlue";            Hex = "#6A5ACD"; R = 106; G = 90;  B = 205 }
        [PSCustomObject]@{ Name = "DarkSlateBlue";        Hex = "#483D8B"; R = 72;  G = 61;  B = 139 }
        [PSCustomObject]@{ Name = "MediumSlateBlue";      Hex = "#7B68EE"; R = 123; G = 104; B = 238 }
        # Greens
        [PSCustomObject]@{ Name = "GreenYellow";          Hex = "#ADFF2F"; R = 173; G = 255; B = 47  }
        [PSCustomObject]@{ Name = "Chartreuse";           Hex = "#7FFF00"; R = 127; G = 255; B = 0   }
        [PSCustomObject]@{ Name = "LawnGreen";            Hex = "#7CFC00"; R = 124; G = 252; B = 0   }
        [PSCustomObject]@{ Name = "Lime";                 Hex = "#00FF00"; R = 0;   G = 255; B = 0   }
        [PSCustomObject]@{ Name = "LimeGreen";            Hex = "#32CD32"; R = 50;  G = 205; B = 50  }
        [PSCustomObject]@{ Name = "PaleGreen";            Hex = "#98FB98"; R = 152; G = 251; B = 152 }
        [PSCustomObject]@{ Name = "LightGreen";           Hex = "#90EE90"; R = 144; G = 238; B = 144 }
        [PSCustomObject]@{ Name = "MediumSpringGreen";    Hex = "#00FA9A"; R = 0;   G = 250; B = 154 }
        [PSCustomObject]@{ Name = "SpringGreen";          Hex = "#00FF7F"; R = 0;   G = 255; B = 127 }
        [PSCustomObject]@{ Name = "MediumSeaGreen";       Hex = "#3CB371"; R = 60;  G = 179; B = 113 }
        [PSCustomObject]@{ Name = "SeaGreen";             Hex = "#2E8B57"; R = 46;  G = 139; B = 87  }
        [PSCustomObject]@{ Name = "ForestGreen";          Hex = "#228B22"; R = 34;  G = 139; B = 34  }
        [PSCustomObject]@{ Name = "Green";                Hex = "#008000"; R = 0;   G = 128; B = 0   }
        [PSCustomObject]@{ Name = "DarkGreen";            Hex = "#006400"; R = 0;   G = 100; B = 0   }
        [PSCustomObject]@{ Name = "YellowGreen";          Hex = "#9ACD32"; R = 154; G = 205; B = 50  }
        [PSCustomObject]@{ Name = "OliveDrab";            Hex = "#6B8E23"; R = 107; G = 142; B = 35  }
        [PSCustomObject]@{ Name = "Olive";                Hex = "#808000"; R = 128; G = 128; B = 0   }
        [PSCustomObject]@{ Name = "DarkOliveGreen";       Hex = "#556B2F"; R = 85;  G = 107; B = 47  }
        [PSCustomObject]@{ Name = "MediumAquamarine";     Hex = "#66CDAA"; R = 102; G = 205; B = 170 }
        [PSCustomObject]@{ Name = "DarkSeaGreen";         Hex = "#8FBC8F"; R = 143; G = 188; B = 143 }
        [PSCustomObject]@{ Name = "LightSeaGreen";        Hex = "#20B2AA"; R = 32;  G = 178; B = 170 }
        [PSCustomObject]@{ Name = "DarkCyan";             Hex = "#008B8B"; R = 0;   G = 139; B = 139 }
        [PSCustomObject]@{ Name = "Teal";                 Hex = "#008080"; R = 0;   G = 128; B = 128 }
        # Blues/Cyans
        [PSCustomObject]@{ Name = "Aqua";                 Hex = "#00FFFF"; R = 0;   G = 255; B = 255 }
        [PSCustomObject]@{ Name = "Cyan";                 Hex = "#00FFFF"; R = 0;   G = 255; B = 255 }
        [PSCustomObject]@{ Name = "LightCyan";            Hex = "#E0FFFF"; R = 224; G = 255; B = 255 }
        [PSCustomObject]@{ Name = "PaleTurquoise";        Hex = "#AFEEEE"; R = 175; G = 238; B = 238 }
        [PSCustomObject]@{ Name = "Aquamarine";           Hex = "#7FFFD4"; R = 127; G = 255; B = 212 }
        [PSCustomObject]@{ Name = "Turquoise";            Hex = "#40E0D0"; R = 64;  G = 224; B = 208 }
        [PSCustomObject]@{ Name = "MediumTurquoise";      Hex = "#48D1CC"; R = 72;  G = 209; B = 204 }
        [PSCustomObject]@{ Name = "DarkTurquoise";        Hex = "#00CED1"; R = 0;   G = 206; B = 209 }
        [PSCustomObject]@{ Name = "CadetBlue";            Hex = "#5F9EA0"; R = 95;  G = 158; B = 160 }
        [PSCustomObject]@{ Name = "SteelBlue";            Hex = "#4682B4"; R = 70;  G = 130; B = 180 }
        [PSCustomObject]@{ Name = "LightSteelBlue";       Hex = "#B0C4DE"; R = 176; G = 196; B = 222 }
        [PSCustomObject]@{ Name = "PowderBlue";           Hex = "#B0E0E6"; R = 176; G = 224; B = 230 }
        [PSCustomObject]@{ Name = "LightBlue";            Hex = "#ADD8E6"; R = 173; G = 216; B = 230 }
        [PSCustomObject]@{ Name = "SkyBlue";              Hex = "#87CEEB"; R = 135; G = 206; B = 235 }
        [PSCustomObject]@{ Name = "LightSkyBlue";         Hex = "#87CEFA"; R = 135; G = 206; B = 250 }
        [PSCustomObject]@{ Name = "DeepSkyBlue";          Hex = "#00BFFF"; R = 0;   G = 191; B = 255 }
        [PSCustomObject]@{ Name = "DodgerBlue";           Hex = "#1E90FF"; R = 30;  G = 144; B = 255 }
        [PSCustomObject]@{ Name = "CornflowerBlue";       Hex = "#6495ED"; R = 100; G = 149; B = 237 }
        [PSCustomObject]@{ Name = "MediumSlateBlue";      Hex = "#7B68EE"; R = 123; G = 104; B = 238 }
        [PSCustomObject]@{ Name = "RoyalBlue";            Hex = "#4169E1"; R = 65;  G = 105; B = 225 }
        [PSCustomObject]@{ Name = "Blue";                 Hex = "#0000FF"; R = 0;   G = 0;   B = 255 }
        [PSCustomObject]@{ Name = "MediumBlue";           Hex = "#0000CD"; R = 0;   G = 0;   B = 205 }
        [PSCustomObject]@{ Name = "DarkBlue";             Hex = "#00008B"; R = 0;   G = 0;   B = 139 }
        [PSCustomObject]@{ Name = "Navy";                 Hex = "#000080"; R = 0;   G = 0;   B = 128 }
        [PSCustomObject]@{ Name = "MidnightBlue";         Hex = "#191970"; R = 25;  G = 25;  B = 112 }
        # Browns
        [PSCustomObject]@{ Name = "Cornsilk";             Hex = "#FFF8DC"; R = 255; G = 248; B = 220 }
        [PSCustomObject]@{ Name = "BlanchedAlmond";       Hex = "#FFEBCD"; R = 255; G = 235; B = 205 }
        [PSCustomObject]@{ Name = "Bisque";               Hex = "#FFE4C4"; R = 255; G = 228; B = 196 }
        [PSCustomObject]@{ Name = "NavajoWhite";          Hex = "#FFDEAD"; R = 255; G = 222; B = 173 }
        [PSCustomObject]@{ Name = "Wheat";                Hex = "#F5DEB3"; R = 245; G = 222; B = 179 }
        [PSCustomObject]@{ Name = "BurlyWood";            Hex = "#DEB887"; R = 222; G = 184; B = 135 }
        [PSCustomObject]@{ Name = "Tan";                  Hex = "#D2B48C"; R = 210; G = 180; B = 140 }
        [PSCustomObject]@{ Name = "RosyBrown";            Hex = "#BC8F8F"; R = 188; G = 143; B = 143 }
        [PSCustomObject]@{ Name = "SandyBrown";           Hex = "#F4A460"; R = 244; G = 164; B = 96  }
        [PSCustomObject]@{ Name = "Goldenrod";            Hex = "#DAA520"; R = 218; G = 165; B = 32  }
        [PSCustomObject]@{ Name = "DarkGoldenrod";        Hex = "#B8860B"; R = 184; G = 134; B = 11  }
        [PSCustomObject]@{ Name = "Peru";                 Hex = "#CD853F"; R = 205; G = 133; B = 63  }
        [PSCustomObject]@{ Name = "Chocolate";            Hex = "#D2691E"; R = 210; G = 105; B = 30  }
        [PSCustomObject]@{ Name = "SaddleBrown";          Hex = "#8B4513"; R = 139; G = 69;  B = 19  }
        [PSCustomObject]@{ Name = "Sienna";               Hex = "#A0522D"; R = 160; G = 82;  B = 45  }
        [PSCustomObject]@{ Name = "Brown";                Hex = "#A52A2A"; R = 165; G = 42;  B = 42  }
        [PSCustomObject]@{ Name = "Maroon";               Hex = "#800000"; R = 128; G = 0;   B = 0   }
        # Whites
        [PSCustomObject]@{ Name = "White";                Hex = "#FFFFFF"; R = 255; G = 255; B = 255 }
        [PSCustomObject]@{ Name = "Snow";                 Hex = "#FFFAFA"; R = 255; G = 250; B = 250 }
        [PSCustomObject]@{ Name = "HoneyDew";             Hex = "#F0FFF0"; R = 240; G = 255; B = 240 }
        [PSCustomObject]@{ Name = "MintCream";            Hex = "#F5FFFA"; R = 245; G = 255; B = 250 }
        [PSCustomObject]@{ Name = "Azure";                Hex = "#F0FFFF"; R = 240; G = 255; B = 255 }
        [PSCustomObject]@{ Name = "AliceBlue";            Hex = "#F0F8FF"; R = 240; G = 248; B = 255 }
        [PSCustomObject]@{ Name = "GhostWhite";           Hex = "#F8F8FF"; R = 248; G = 248; B = 255 }
        [PSCustomObject]@{ Name = "WhiteSmoke";           Hex = "#F5F5F5"; R = 245; G = 245; B = 245 }
        [PSCustomObject]@{ Name = "SeaShell";             Hex = "#FFF5EE"; R = 255; G = 245; B = 238 }
        [PSCustomObject]@{ Name = "Beige";                Hex = "#F5F5DC"; R = 245; G = 245; B = 220 }
        [PSCustomObject]@{ Name = "OldLace";              Hex = "#FDF5E6"; R = 253; G = 245; B = 230 }
        [PSCustomObject]@{ Name = "FloralWhite";          Hex = "#FFFAF0"; R = 255; G = 250; B = 240 }
        [PSCustomObject]@{ Name = "Ivory";                Hex = "#FFFFF0"; R = 255; G = 255; B = 240 }
        [PSCustomObject]@{ Name = "AntiqueWhite";         Hex = "#FAEBD7"; R = 250; G = 235; B = 215 }
        [PSCustomObject]@{ Name = "Linen";                Hex = "#FAF0E6"; R = 250; G = 240; B = 230 }
        [PSCustomObject]@{ Name = "LavenderBlush";        Hex = "#FFF0F5"; R = 255; G = 240; B = 245 }
        [PSCustomObject]@{ Name = "MistyRose";            Hex = "#FFE4E1"; R = 255; G = 228; B = 225 }
        # Grays/Blacks
        [PSCustomObject]@{ Name = "Gainsboro";            Hex = "#DCDCDC"; R = 220; G = 220; B = 220 }
        [PSCustomObject]@{ Name = "LightGray";            Hex = "#D3D3D3"; R = 211; G = 211; B = 211 }
        [PSCustomObject]@{ Name = "Silver";               Hex = "#C0C0C0"; R = 192; G = 192; B = 192 }
        [PSCustomObject]@{ Name = "DarkGray";             Hex = "#A9A9A9"; R = 169; G = 169; B = 169 }
        [PSCustomObject]@{ Name = "Gray";                 Hex = "#808080"; R = 128; G = 128; B = 128 }
        [PSCustomObject]@{ Name = "DimGray";              Hex = "#696969"; R = 105; G = 105; B = 105 }
        [PSCustomObject]@{ Name = "LightSlateGray";       Hex = "#778899"; R = 119; G = 136; B = 153 }
        [PSCustomObject]@{ Name = "SlateGray";            Hex = "#708090"; R = 112; G = 128; B = 144 }
        [PSCustomObject]@{ Name = "DarkSlateGray";        Hex = "#2F4F4F"; R = 47;  G = 79;  B = 79  }
        [PSCustomObject]@{ Name = "Black";                Hex = "#000000"; R = 0;   G = 0;   B = 0   }
    )

    if (-not [string]::IsNullOrWhiteSpace($Filter)) {
        $htmlColors = $htmlColors | Where-Object { $_.Name -match $Filter }
    }

    Write-Host "`n=== HTML Color Codes (https://htmlcolorcodes.com/color-names/) ===" -ForegroundColor Cyan
    Write-Host "Total: $($htmlColors.Count) colors`n" -ForegroundColor Gray

    foreach ($color in $htmlColors) {
        $label = $color.Name.PadRight(25)
        $hex   = $color.Hex.PadRight(10)
        $rgb   = "rgb($($color.R), $($color.G), $($color.B))"
        Write-Host "$label $hex $rgb"
    }

    Write-Host ""
    return $htmlColors
}

Set-Alias htmlcolors Get-HtmlColorCodes
Set-Alias colornames Get-HtmlColorCodes

#usage Get-HtmlColorCodes
#usage Get-HtmlColorCodes -Filter "blue"
#usage htmlcolors
#usage colornames

function Get-ContrastingColors {
    <#
    .SYNOPSIS
        Returns 10 HTML color names that are highly contrasting with each other

    .DESCRIPTION
        Returns an array of 10 HTML named colors that are maximally distinct from one another
        in terms of hue, saturation, and luminance — useful for charts, visualizations,
        or any scenario requiring clearly distinguishable colors.

    .EXAMPLE
        Get-ContrastingColors
        Returns and displays 10 highly contrasting color names

    .EXAMPLE
        $colors = Get-ContrastingColors
        $colors.Name
        Returns just the color names as strings
    #>
    [CmdletBinding()]
    param()

    $contrastingColors = @(
        [PSCustomObject]@{ Name = "Red";       Hex = "#FF0000"; R = 255; G = 0;   B = 0   }
        [PSCustomObject]@{ Name = "Blue";      Hex = "#0000FF"; R = 0;   G = 0;   B = 255 }
        [PSCustomObject]@{ Name = "Lime";      Hex = "#00FF00"; R = 0;   G = 255; B = 0   }
        [PSCustomObject]@{ Name = "Yellow";    Hex = "#FFFF00"; R = 255; G = 255; B = 0   }
        [PSCustomObject]@{ Name = "Cyan";      Hex = "#00FFFF"; R = 0;   G = 255; B = 255 }
        [PSCustomObject]@{ Name = "Magenta";   Hex = "#FF00FF"; R = 255; G = 0;   B = 255 }
        [PSCustomObject]@{ Name = "Orange";    Hex = "#FFA500"; R = 255; G = 165; B = 0   }
        [PSCustomObject]@{ Name = "Purple";    Hex = "#800080"; R = 128; G = 0;   B = 128 }
        [PSCustomObject]@{ Name = "Black";     Hex = "#000000"; R = 0;   G = 0;   B = 0   }
        [PSCustomObject]@{ Name = "White";     Hex = "#FFFFFF"; R = 255; G = 255; B = 255 }
    )

    Write-Host "`n=== 10 Highly Contrasting HTML Colors ===" -ForegroundColor Cyan
    Write-Host "These colors are maximally distinct in hue and luminance.`n" -ForegroundColor Gray

    foreach ($color in $contrastingColors) {
        $label = $color.Name.PadRight(12)
        $hex   = $color.Hex.PadRight(10)
        $rgb   = "rgb($($color.R), $($color.G), $($color.B))"
        Write-Host "$label $hex $rgb"
    }

    Write-Host ""
    return $contrastingColors
}

Set-Alias contrastcolors Get-ContrastingColors
Set-Alias top10colors Get-ContrastingColors

#usage Get-ContrastingColors
#usage contrastcolors
#usage top10colors
