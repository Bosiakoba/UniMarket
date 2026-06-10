$base = "e:\Pro\UniMarket\unimarket\assets\figma"
$dirs = @("auth","splash","onboarding\page1","onboarding\page2","onboarding\page3","verification","profile","nav")
foreach ($d in $dirs) { New-Item -ItemType Directory -Force -Path (Join-Path $base $d) | Out-Null }

$assets = @{
  "auth\logo_shopping_bag" = "https://www.figma.com/api/mcp/asset/45615ad3-0ed2-4b01-a7b5-ed1f7894a3b4"
  "auth\google" = "https://www.figma.com/api/mcp/asset/0aba0867-e004-4d63-9fab-23a51658121f"
  "auth\apple" = "https://www.figma.com/api/mcp/asset/eb9171c5-74ab-42cc-bbec-f7208c04e568"
  "splash\logo" = "https://www.figma.com/api/mcp/asset/e847db78-46f8-4a6e-8034-58204e97cb49"
  "onboarding\page1\collage_1" = "https://www.figma.com/api/mcp/asset/6360795e-f9f6-4ef0-a819-6ced184cdc14"
  "onboarding\page1\collage_2" = "https://www.figma.com/api/mcp/asset/4490e4f9-dcdc-4f7f-bf7e-83b9dedf27f4"
  "onboarding\page1\collage_3" = "https://www.figma.com/api/mcp/asset/790150c1-61ec-4c75-9b9e-5d247ba2b789"
  "onboarding\page1\collage_4" = "https://www.figma.com/api/mcp/asset/675dac41-c345-44d0-82b1-1597865ff142"
  "onboarding\page1\collage_5" = "https://www.figma.com/api/mcp/asset/d4b40814-6c4c-47b4-9b3d-391ce8c1d282"
  "onboarding\page1\collage_6" = "https://www.figma.com/api/mcp/asset/cbcb9c9e-462d-4d59-b561-d8377dd86035"
  "onboarding\page1\collage_7" = "https://www.figma.com/api/mcp/asset/33c53a16-1e70-4469-baaa-3b4524d82015"
  "onboarding\page1\collage_8" = "https://www.figma.com/api/mcp/asset/db26ce58-9650-4382-8b73-a465d04cf6be"
  "onboarding\page1\collage_9" = "https://www.figma.com/api/mcp/asset/44db1d92-8e5b-4dbf-9170-769c7ab989e3"
  "onboarding\page1\logo" = "https://www.figma.com/api/mcp/asset/aef8b2b4-e8cb-42dc-89bd-848d5149dfe8"
  "onboarding\page1\arrow" = "https://www.figma.com/api/mcp/asset/8becbe66-8c25-487b-a5bb-0867139dd3c4"
  "onboarding\page2\logo" = "https://www.figma.com/api/mcp/asset/a1d83564-1127-4b28-9a1e-564122961e38"
  "onboarding\page2\sneaker" = "https://www.figma.com/api/mcp/asset/30f203a2-34da-46f0-a0da-702086529e8f"
  "onboarding\page2\produce" = "https://www.figma.com/api/mcp/asset/a7c35ce9-3c84-4ba1-a042-29d1afda80ea"
  "onboarding\page2\perfume" = "https://www.figma.com/api/mcp/asset/9c6e8c71-b2ce-4578-89ca-572335acbdcb"
  "onboarding\page2\arrow" = "https://www.figma.com/api/mcp/asset/90bd2a66-0342-448d-9eea-45a73483e08a"
  "onboarding\page3\logo" = "https://www.figma.com/api/mcp/asset/4fffc394-fb98-41f4-a398-40dd5fc01f48"
  "onboarding\page3\money_top" = "https://www.figma.com/api/mcp/asset/d2d6119f-3d12-41b5-a355-64d7d3637a29"
  "onboarding\page3\money_bottom" = "https://www.figma.com/api/mcp/asset/745b0e35-da45-49a8-b96a-f2f4f6b6302b"
  "onboarding\page3\arrow" = "https://www.figma.com/api/mcp/asset/2da3f20b-3b5a-4282-9da3-e86ba33ce942"
  "verification\illustration" = "https://www.figma.com/api/mcp/asset/25c11eb7-f4fe-49e3-8176-a8687f1c7e8a"
  "profile\progress_meter" = "https://www.figma.com/api/mcp/asset/5ba4cf06-664e-4e46-a502-5887fb35e9b0"
  "nav\home" = "https://www.figma.com/api/mcp/asset/984258ff-9547-433a-8204-bc627420f8e7"
  "nav\search" = "https://www.figma.com/api/mcp/asset/92fd66f5-a377-44d4-9d00-7564f4eaf1ea"
  "nav\heart" = "https://www.figma.com/api/mcp/asset/3314e3b9-ed99-4201-ba3d-e4d21be394f0"
  "nav\bag" = "https://www.figma.com/api/mcp/asset/5d7d6054-403e-4f43-99ab-aad0d8fb5f4d"
  "nav\user" = "https://www.figma.com/api/mcp/asset/feef13ec-db38-48ad-96d6-573e2cd15de3"
  "nav\envelope" = "https://www.figma.com/api/mcp/asset/17f82bec-1517-421b-bdf5-21b79ea23390"
  "nav\bell" = "https://www.figma.com/api/mcp/asset/3bbe984a-02c0-4dc3-b354-58c9f1a4972f"
}

foreach ($entry in $assets.GetEnumerator()) {
  $tmp = Join-Path $base "$($entry.Key).bin"
  Invoke-WebRequest -Uri $entry.Value -OutFile $tmp -UseBasicParsing
  $bytes = [System.IO.File]::ReadAllBytes($tmp)
  $header = [System.Text.Encoding]::ASCII.GetString($bytes[0..3])
  $ext = if ($header.StartsWith("<svg") -or $header.StartsWith("<?xm")) { ".svg" } else { ".png" }
  $dest = Join-Path $base "$($entry.Key)$ext"
  Move-Item -Force $tmp $dest
  Write-Output "$dest ($ext)"
}
