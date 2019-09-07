# Multus default route manipulation from within the POD 

This script was created to bypass the Multus limitation where default routes cannot be defined during Network CRD creation
Ideally this script can me mounted using a configMap with an Init Container. For testing purpose , you can run this script once the POD is created and depending on your privlege level
