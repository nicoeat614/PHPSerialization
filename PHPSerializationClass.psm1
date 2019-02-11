using namespace System;
using namespace System.Text;
using namespace System.Collections;
using namespace System.Collections.Generic;

class PHPSerialization 
{

<#
        types:
        N = null
	    s = string
		i = int
		d = double
		a = array (hashtable)
#>

hidden [Dictionary[[List[Object]],[Bool]]]$seenArrayLists
hidden [Dictionary[Dictionary[[Object],[Object]],[Bool]]]$seenHashTables

hidden [int]$pos = $null

[bool]$XMLSafe = $true 

[Encoding]$StringEncoding = [Encoding]::UTF8

hidden [Globalization.NumberFormatInfo]$nfi

PHPSerialization()
    {
        $this.nfi = [Globalization.NumberFormatInfo]::new()
        $this.nfi.NumberGroupSeparator = ""
        $this.nfi.NumberDecimalSeparator = "."
    }

[String] Serialize([System.Object]$obj)
    {
        $this.seenArrayLists = [Dictionary[[List[Object]],[Bool]]]::new()
        $this.seenHashTables = [Dictionary[Dictionary[[Object],[Object]],[Bool]]]::new()
   

        return $this.Serialize($obj, [StringBuilder]::new()).ToString()
    }

hidden [StringBuilder] Serialize([System.Object]$obj, [StringBuilder]$sb)
    {
        if ($obj -eq $null) {
            return $sb.Append("N;")
            }
    
        elseif ($obj -is [String]) {
            [string]$str = $obj -as [string]

            if($this.XMLSafe) {
                $str = $str.Replace("`r`n", "`n")
                $str = $str.Replace("`r", "`n")           
                    }

                return $sb.Append("s:" + $this.StringEncoding.GetByteCount($str) + ':' + $str + ';')
            }

        elseif ($obj -is [bool]) {
            return $sb.Append("b:" + ([bool]::Equals($obj, $null)) + ";")
                }

        elseif ($obj -is [int]) {
            [int]$i = $obj -as [int]        
            return $sb.Append("i:" + $i.ToString($this.nfi) + ";") 
                }

        elseif ($obj -is [long]) {
            [long]$i = $obj -as [long]
            return $sb.Append("i:" + $i.ToString($this.nfi) + ";")
                    }

        elseif($obj -is [double]) {			
			    [double]$d = $obj -as [double]				
			    return $sb.Append("d:" + $d.ToString($this.nfi) + ";")
			        }

        elseif($obj -is [List[Object]]) {
			
                if ($this.seenArrayLists.ContainsKey(($obj -as [List[Object]]))) {
                    return $sb.Append("N;") } #cycle detected 
                
                    $this.seenArrayLists.Add(($obj -as [List[Object]]), $true)

			    $a = ($obj -as [List[Object]])
			    $sb.Append("a:" + $a.Count + ":{")
			        for ($i = 0; $i -lt $a.Count; $i++)
			        {
				        $this.serialize($i, $sb)
				        $this.serialize($a[$i], $sb)
			        }
			    $sb.Append("}")
			    return $sb			
            }

       elseif($obj -is [Dictionary[[object],[Object]]]) {
			
                if ($this.seenHashtables.ContainsKey(($obj -as [Dictionary[[object],[Object]]]))) {
                    return $sb.Append("N;") 
                        } 
                
                    $this.seenHashtables.Add(($obj -as [Hashtable]), $true)

			        $a = ($obj -as [Dictionary[[object],[Object]]])
			        $sb.Append("a:" + $a.Count + ":{")
			            foreach ($entry in $a.GetEnumerator()) { #GetEnumerator Method doesn't do anything			            
				            $this.serialize($entry.Keys, $sb)
				            $this.serialize($entry.Value, $sb)
			                   }

			        $sb.Append("}")
			        return $sb			
            }

         else {
            return $sb
                }
    }

[object]Deserialize([String]$str)
{
    $this.pos = 0
    return $this.UnserializationProcess($str)
}


hidden [object] UnserializationProcess([string]$str)
{
    if (($str -eq $null) -and ($str.Length -le $this.pos)) {
        return [Object]::new() }

        [int]$start = $null
        [int]$end = $null
        [int]$length = $null
        [string]$stLen = $null
        

       $serialreturn = switch ($str[$this.pos]) {

            'N' {$this.pos += 2; return $null}
            'b' {[char]$chBool = $null; $chBool = $str[$this.pos + 2]; $this.pos += 4; return $chBool -eq '1'}
            'i' {[string]$stInt = $null; $start = $str.IndexOf(":", $this.pos) + 1;
                 $end = $str.IndexOf(";", $start); $stInt = $str.Substring($start, $end - $start);
                 $this.pos += 3 + $stInt.Length; [object]$oRet = $null;
                 Try {
                    $oRet = [int]::Parse($stInt, $this.nfi)
                        }
                 Catch {
                     $oRet = [long]::Parse($stInt, $this.nfi)   
                        }   
                 return $oRet
                 }

            'd' {[string]$stDouble = $null; $start = $str.IndexOf(":", $this.pos) + 1;
                 $end = $str.IndexOf(";", $start); $stDouble = $str.Substring($start, $end - $start);
				 $this.pos += 3 + $stDouble.Length;                    
				 return [double]::Parse($stDouble, $this.nfi)}

            's' {$start = $str.IndexOf(":", $this.pos) + 1; $end = $str.IndexOf(":", $start);
                 $stLen = $str.Substring($start, $end - $start); [int]$bytelen = [int]::Parse($stLen);
                 $length = $bytelen
                 if (($end + 2 + $length) -ge $str.Length) {$length = $str.Length - 2 - $end};
                 [string]$stRet = $str.Substring($end + 2, $length);
                 while ($this.StringEncoding.GetByteCount($stRet) -gt $bytelen) {
                      $length--
                      $stRet = $str.Substring($end + 2, $length)
                            }
                 $this.pos += 6 + $stLen.Length + $length;
                 if ($this.XMLSafe) {
                    $stRet = $stRet.Replace("`n", "`r`n")
                            }
                    return $stRet           
                 }

            'a' {$start = $str.IndexOf(":", $this.pos) + 1; $end = $str.IndexOf(":", $start);
                 $stLen = $str.Substring($start, $end - $start); $length = [int]::Parse($stLen);
                 $script:htRet = [Dictionary[[object],[Object]]]::new($length); $script:alRet = [List[Object]]::new($length);
                 $this.pos += 4 + $stLen.Length;
                 for ($i = 0; $i -lt $length; $i++) {
                 
						[object]$key = $this.UnserializationProcess($str)
						[object]$val = $this.UnserializationProcess($str)
                        
                        if ($script:altRet -ne $null) {
                            if ($key -is [int] -and $key -eq $script:alRet.Count) {
                                $script:altRet.Add($val) }
                                             
                            else { $altRet = $null }
                                            }
                                            
                            $script:htRet[$key] = $val
                                    } #end of for statement

                 $this.pos++;
                 if ($this.pos -lt $str.Length -and $str[$this.pos] -eq ';') {
                    $this.pos++}
                 if ($script:altRet -ne $null) {
                    return $script:alRet
                            }
                 else {
                    return $script:htRet #($script:htRet.GetEnumerator() | Sort Name Sorting)
                         }
                 } 

            default {
                return ""
                 }

        } # end of switch

        return $serialreturn
    }

} #End of Class
