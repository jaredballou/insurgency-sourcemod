<?php
// This script generates a keyvalues file from a sourcemod netprop dump
// for use with https://forums.alliedmods.net/showthread.php?t=143081
// by Peace-Maker
// visit http://www.wcfan.de/

// file in the same directory to read from generated with sourcemod
// sm_dump_netprops filename.txt
//$fs = fopen('/home/insserver/serverfiles/insurgency/netprops.txt', 'r');
$data = explode("\n",file_get_contents('/home/insserver/serverfiles/insurgency/netprops.txt'));
// file to write to
//$fs2 = fopen('netprops.insurgency.cfg', 'w');
$kv = array();

$output = "\"NetProps\"\r\n{\r\n";
//var_dump($data);
$i = 0;
//while (!feof($fs))
foreach ($data as $line)
{
$line = rtrim($line);
//    $line = fgets($fs, 4096*2);
//var_dump($line);
//CBaseAnimating (type DT_BaseAnimating)
//$line[strlen($line)-3] == ":") // i use -3 here using a linux dump. if you've got problems on windowsdumps set this to -2
    if(substr($line, 0, 1) != " " && preg_match("/^(.*)\s+\(type (.*)\)$/", $line, $matches))
    {
        if($i > 0)
            $output.="\t}\r\n";
        
        $kv[$i+1] = array();
        $kv[$i+1]['class'] = $matches[1];
        $output.="\t\"{$matches[1]}\"\r\n\t{\r\n";
        $i++;
        continue;
    }
//   Member: m_nMaxGPULevel (offset 519) (type integer) (bits 3) (Unsigned)
//echo "testing preg\n";    
    if(preg_match("/\s+\Member\: (.*) \(offset (\d*)\) \(type (.*)\) \(bits (\d*)\)\s/", $line, $matches))
    {
//var_dump($matches);
        if(is_numeric($matches[1]) || strstr($matches[1], "\""))
            continue;
        
        if(array_key_exists($matches[1], $kv[$i]))
        {
            foreach($kv[$i] as $prop => $info)
            {
                if($prop == $matches[1] && $info['offset'] == $matches[2])
                {
                    continue 2;
                }
            }
        }
        
        $output.="\t\t\"{$matches[1]}\"\r\n\t\t{\r\n\t\t\t\"bits\"\t\"{$matches[4]}\"\r\n\t\t\t\"offset\"\t\"{$matches[2]}\"\r\n\t\t\t\"type\"\t\"{$matches[3]}\"\r\n\t\t}\r\n";
        $kv[$i][$matches[1]] = array('offset' => $matches[2], 'type' => $matches[3], 'bits' => $matches[4]);
    }
}
$output.="\t}\r\n}\r\n";
file_put_contents('netprops.insurgency.cfg',$output);
//echo $output;
//fclose($fs2);
//fclose($fs);
?>
