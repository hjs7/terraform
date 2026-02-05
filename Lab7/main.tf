resource "azapi_resource" "rg" {
    type      = "Microsoft.Resources/resourceGroups@2021-04-01"
    name      = "rg-${var.application_name}-${var.environment_name}"
    location  = var.primary_location
    parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
}

data "azapi_client_config" "current" {}

resource "azapi_resource" "vm_pip" {
  type = "Microsoft.Network/publicIPAddresses@2025-03-01"
  name = "pip-${var.application_name}-${var.environment_name}"
  location = azapi_resource.rg.location
  parent_id = azapi_resource.rg.id
  
  body = {
    properties = {
        publicIPAddressVersion = "IPv4"
        publicIPAllocationMethod = "Static"
    }
    sku = {
        name = "Standard"
    }
  }
}

data "azapi_resource" "network_rg" {
  name = "rg-network-dev"
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type = "Microsoft.Resources/resourceGroups@2021-04-01"
}

data "azapi_resource" "vnet" {
  name = "vnet-network-dev"
  parent_id = data.azapi_resource.network_rg.id
  type = "Microsoft.Network/virtualNetworks@2025-03-01"
}

data "azapi_resource" "subnet_bravo" {
  name = "snet-bravo"
  parent_id = data.azapi_resource.vnet.id
  type = "Microsoft.Network/virtualNetworks/subnets@2025-03-01"

  response_export_values = ["name"]
}

resource "azapi_resource" "vm1_nic" {
  type      = "Microsoft.Network/networkInterfaces@2025-03-01"
  parent_id = data.azapi_resource.network_rg.id
  name      = "nic-${var.application_name}-${var.environment_name}"
  location  = data.azapi_resource.network_rg.location
  body = {
    properties = {
      ipConfigurations = [
        {
          name = "Public"
          properties = {
            subnet = {
              id = data.azapi_resource.subnet_bravo.id
            }
            privateIPAllocationMethod = "Dynamic"
            publicIPAddress = {
              id = azapi_resource.vm_pip.id
            }
          }
        }
      ]
    }
  }
}

resource "tls_private_key" "vm1" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

data "azapi_resource" "devops_rg" {
  name = "rg-devops-dev"
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type = "Microsoft.Resources/resourceGroups@2021-04-01"
}

data "azapi_resource" "keyvault" {
  name = "kv-devops-dev-qmeite"
  parent_id = data.azapi_resource.devops_rg.id
  type = "Microsoft.KeyVault/vaults@2023-07-01"
}

resource "azapi_resource" "vm1_ssh_private" {
  type        = "Microsoft.KeyVault/vaults/secrets@2023-02-01"
  name       = "azapivm-ssh-private"
  parent_id = data.azapi_resource.keyvault.id
  schema_validation_enabled = false
  body = {
    properties = {
      value = tls_private_key.vm1.private_key_pem
    }
  }
  lifecycle {
    ignore_changes = [location]
  }
}

resource "azapi_resource" "vm1_ssh_public" {
  type        = "Microsoft.KeyVault/vaults/secrets@2023-02-01"
  name       = "azapivm-ssh-public"
  parent_id = data.azapi_resource.keyvault.id
  body = {
    properties = {
      value = tls_private_key.vm1.public_key_openssh
    }
  }
}

resource "azapi_resource" "vm1" {
  type      = "Microsoft.Compute/virtualMachines@2023-03-01"
  parent_id = data.azapi_resource.devops_rg.id
  name      = "vm1-${var.application_name}-${var.environment_name}"
  location  = data.azapi_resource.network_rg.location
  body = {
    properties = {
      hardwareProfile = {
        vmSize = "Standard_D2_v2_Promo"
      }
      networkProfile = {
        networkInterfaces = [
          {
            id = azapi_resource.vm1_nic.id
          }
        ]
      }
      osProfile = {
        adminUsername = "adminuser"
        computerName  = "vm1-${var.application_name}-${var.environment_name}"
        linuxConfiguration = {
          ssh = {
            publicKeys = [
              {
                keyData  = tls_private_key.vm1.public_key_openssh
                path     = "/home/adminuser/.ssh/authorized_keys"
              }
            ]
          }
        }
      }


      storageProfile = {
        imageReference = {
          offer     = "UbuntuServer"
          publisher = "Canonical"
          sku       = "16.04-LTS"
          version   = "latest"
        }
          osDisk = {
          caching                 = "ReadWrite"
          createOption            = "FromImage"
          managedDisk = {
            storageAccountType = "Standard_LRS"
          }
        }
      }
    }
  }
}