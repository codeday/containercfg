#!/usr/bin/env bash
cd "$(dirname "$0")"

NAME=srnd-nomad-agent-$(hexdump -n 4 -e '4/4 "%08x" 1 "\n"' /dev/random)

az vm create \
  --name $NAME \
  --tags role=nomad-agent \
  --image UbuntuLTS \
  --size Standard_D2_v3 \
  --admin-username srnd \
  --subscription 49f7105a-6649-48da-b7fd-97c41104d914 \
  --location northcentralus \
  --ssh-key-value id_rsa.pub \
  --resource-group srnd-nomad \
  --availability-set SRND-NOMAD-AGENT \
  --vnet-name srnd-nomad-vnet \
  --subnet default \
  --nsg srnd-nomad-agent-nsg \
  --assign-identity --scope /subscriptions/49f7105a-6649-48da-b7fd-97c41104d914/resourcegroups/srnd-nomad \

# --attach-data-disks
# --custom-data MyCloudInitScript.yml



#curl 'https://management.azure.com/batch?api-version=2015-11-01' -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0' -H 'Accept: */*' -H 'Accept-Language: en' --compressed -H 'Referer: https://portal.azure.com/' -H 'Content-Type: application/json' -H 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6InBpVmxsb1FEU01LeGgxbTJ5Z3FHU1ZkZ0ZwQSIsImtpZCI6InBpVmxsb1FEU01LeGgxbTJ5Z3FHU1ZkZ0ZwQSJ9.eyJhdWQiOiJodHRwczovL21hbmFnZW1lbnQuY29yZS53aW5kb3dzLm5ldC8iLCJpc3MiOiJodHRwczovL3N0cy53aW5kb3dzLm5ldC8zMzNjNWFjNy1kN2M0LTQwN2ItYTVjMy1mZDU1NTFiYWJmMzgvIiwiaWF0IjoxNTc5MDQxMjU4LCJuYmYiOjE1NzkwNDEyNTgsImV4cCI6MTU3OTA0NTE1OCwiYWNyIjoiMSIsImFpbyI6IjQyTmdZRGlWWjlOOTlHUnptbTU3alZMZ1piVVhQcDA5RzFpU1dKb3ZSVGRkV3ptdFNSUUEiLCJhbXIiOlsicHdkIl0sImFwcGlkIjoiYzQ0YjQwODMtM2JiMC00OWMxLWI0N2QtOTc0ZTUzY2JkZjNjIiwiYXBwaWRhY3IiOiIyIiwiZmFtaWx5X25hbWUiOiJNZW5lemVzIiwiZ2l2ZW5fbmFtZSI6IlR5bGVyIiwiZ3JvdXBzIjpbImE0ZTI4MWM1LWUzNTMtNDMzNS05MWVmLTdhYmQxMzZlMWE0MSIsIjRlMGEzYzNmLTQwMGEtNGRhNy1iNTIwLWUxNmJmZmUyYTc5YSIsIjQ0YjMxNTEyLTc0YmEtNDY2NC1iODg4LTNhOWJjM2UzMWYwZSJdLCJpcGFkZHIiOiIyNC4xNy4yNDUuMjM1IiwibmFtZSI6IlR5bGVyIE1lbmV6ZXMiLCJvaWQiOiJhOTI0MmJjYS05OTExLTRiOTEtOTBmNi1mMmExN2NmNzdmZTMiLCJvbnByZW1fc2lkIjoiUy0xLTUtMjEtMzU3MDUyODAyMS0xNzUwNjA5MjgwLTI1MDcyMDk1NjEtMTEwMyIsInB1aWQiOiIxMDAzQkZGRDk5Q0QwRjY1Iiwic2NwIjoidXNlcl9pbXBlcnNvbmF0aW9uIiwic3ViIjoiR1dral9EMjNjWl9yYUkwY0ZDbVlHcnJZM2M1bnlqcVFhdmgtOXdveXFCOCIsInRpZCI6IjMzM2M1YWM3LWQ3YzQtNDA3Yi1hNWMzLWZkNTU1MWJhYmYzOCIsInVuaXF1ZV9uYW1lIjoidHlsZXJtZW5lemVzQHNybmQub3JnIiwidXBuIjoidHlsZXJtZW5lemVzQHNybmQub3JnIiwidXRpIjoiZzRoMWFULTZHa200X0VXXzQyX3RBQSIsInZlciI6IjEuMCIsIndpZHMiOlsiNjJlOTAzOTQtNjlmNS00MjM3LTkxOTAtMDEyMTc3MTQ1ZTEwIl19.ojt6mjhPfW6tmBEFl9DffmskYO9eB9bKX2N2RiGbM8lxPZnkcYrLX-BildH7WkMVnYZ0Xmn9_6R4TKkeYnDqAgEM0cs56PIGfeBUGILWLQxqmVWlOGCu0Q_UX-3mj5vb1ZqIVg8jxdhnxJ2oYMNtO2qdfGxt-fkuq1bdv-2qyTnYjP5nYRUlwDr3jshFsyDMa_59tIVxYgP_7wSkRTbkfVE1K2VXx6alP_3vPNXoOR9ay5MVQLTgYWB-VJ5iB2LIGSZM9g2qVaEXcgQuu_fJat4DE-CYRK5Djq1lFXN9t5RpGFbIukP2LgvjigQVEdfxACv1EDhQCmsEqtt5uzJy4A' -H 'x-ms-command-name: { Microsoft_Azure_AD.Batch:0,Unknown:1}' -H 'x-ms-effective-locale: en.en-us' -H 'x-ms-client-request-id: 461c0504-72f3-4d58-b9ac-09a253cd000d' -H 'x-ms-client-session-id: e14f6b9b0a6143b4b7bf2dd1ade5e082' -H 'Origin: https://portal.azure.com' -H 'Connection: keep-alive' -H 'TE: Trailers' --data '{"requests":[{"content":{"Id":"6050b417-53f6-47a0-968b-0cc6872c7866","Properties":{"PrincipalId":"adaae345-5e74-469b-babc-fd13abc97986","RoleDefinitionId":"/subscriptions/49f7105a-6649-48da-b7fd-97c41104d914/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c","Scope":"/subscriptions/49f7105a-6649-48da-b7fd-97c41104d914"}},"httpMethod":"PUT","requestHeaderDetails":{"commandName":"Microsoft_Azure_AD."},"url":"https://management.azure.com/subscriptions/49f7105a-6649-48da-b7fd-97c41104d914/providers/Microsoft.Authorization/roleAssignments/6050b417-53f6-47a0-968b-0cc6872c7866?api-version=2018-01-01-preview"}]}'
