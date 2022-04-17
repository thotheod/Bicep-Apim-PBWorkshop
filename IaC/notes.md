# APIM Soft delete options

## list all soft deleted apims
az rest --method get --header "Accept=application/json" \
-u  'https://management.azure.com/subscriptions/0a52391c-0d81-434e-90b4-d04f5c670e8a/providers/Microsoft.ApiManagement/deletedservices?api-version=2021-08-01'
## Purge soft deleted apim
az rest --method delete --header "Accept=application/json" \
-u 'https://management.azure.com/subscriptions/0a52391c-0d81-434e-90b4-d04f5c670e8a/providers/Microsoft.ApiManagement/locations/northeurope/deletedservices/apim-apimPoc-NE-dev?api-version=2020-06-01-preview'