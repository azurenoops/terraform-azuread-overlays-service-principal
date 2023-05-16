# Azure AD Service Principal Overlay Terraform Module

[![Changelog](https://img.shields.io/badge/changelog-release-green.svg)](CHANGELOG.md) [![MIT License](https://img.shields.io/badge/license-MIT-orange.svg)](LICENSE) [![TF Registry](https://img.shields.io/badge/terraform-registry-blue.svg)](https://registry.terraform.io/modules/azurenoops/overlays-service-principal/azuread/)

This Terraform Module creates an service principal and assign required built-in roles. The outputs from this module, like application_id and password, can be used as an input in other modules.

To create a service principal and assign roles to the resources, this module needed elevated access in both Azure AD and Azure subscription. Therefore, it is not suggested to run from any CI/CD pipelines and advised to run manually to proceed with automated methods.

## Overlay Module Usage

```hcl
# Azurerm provider configuration
provider "azurerm" {
  features {}
}
module "mod_service_principal" {
  source  = "azurenoops/overlays-service-principal/azuread"
  version = "x.x.x"
  service_principal_name     = "dev-app-sp"
  service_principal_password_rotation_in_years = 1
  # Adding roles and scope to service principal
  service_principal_assignments = [
    {
      scope                = "/subscriptions/xxxxx000-0000-0000-0000-xxxx0000xxxx"
      role_definition_name = "Contributor"
    },
  ]
}
```

## Create a service principal with a certificate

You can create an identity for your app and use its unique credentials to authenticate it when it wants to access services. A service principle is the name given to this identification. With this approach, you can:

* Provide the app identification access rights that are distinct from your own. These permissions are often limited to what the app actually requires to perform.
* Use a certificate for authentication when executing an unattended script.

This module uses a certificate to create the service principal. Enabling this requires setting up "enable service principal certificate = true" and providing the proper certificate path with the "certificate path" argument.

```hcl
# Azurerm provider configuration
provider "azurerm" {
  features {}
}
module "mod_service_principal" {
  source  = "azurenoops/overlays-service-principal/azuread"
  version = "x.x.x"
  service_principal_name               = "dev-app-sp"
  enable_service_principal_certificate = true
  certificate_path                     = "./cert.pem"
  service_principal_password_rotation_in_years           = 1
  # Adding roles and scope to service principal
  service_principal_assignments = [
    {
      scope                = "/subscriptions/xxxxx000-0000-0000-0000-xxxx0000xxxx"
      role_definition_name = "Contributor"
    },
  ]
}
```

> In addition to the previously available technique of specifying the filesystem path for a.pfx file, it is now allowed to specify the certificate bundle data as an inline variable if you are utilizing Client Certificate authentication. When using Terraform in a non-interactive setting, such as CI/CD pipelines, this can be helpful.
> This can be enabled by replacing existing encoding value with argument `certificate_encoding = "base64"` and provide a valid .pfx certificate path using the argument `certificate_path`.
> The `hex` encoding option (`certificate_encoding = "hex"`) is useful for consuming certificate data from the `azurerm_key_vault_certificate` resource.

## Create X.509 Certificate with Asymmetric Keys

To create a self signed SSL certificate, execute the following OpenSSL command, replacing the -days and -subj parameters with the appropriate values:

```sh
openssl req -x509 -days 3650 -newkey rsa:2048 -out cert.pem -nodes -subj '/CN=dev-app-sp'
```

The "cert.pem" and "privkey.pem" files will be created by this command. The X.509 certificate with public key is contained in the "cert.pem" file. The Active Directory Application will get this certificate as an attachment. The RSA private key for the Service Principal's Azure Active Directory authentication is stored in the "privkey.pem" file.

When self-signed certificates are not sufficient, sign your certificate using a Third-Party Certificate Authority such as Verisign, GeoTrust, or some other Internal Certificate Authority by generating a certificate signing request (CSR).

## Password rotation using `time_rotating`

Manages a rotating time resource, which keeps a rotating UTC timestamp stored in the Terraform state and proposes resource recreation when the locally sourced current time is beyond the rotation time. This rotation only occurs when Terraform is executed, meaning there will be drift between the rotation timestamp and actual rotation.

> From version 2.0 the AzureAD provider exclusively uses Microsoft Graph to connect to Azure Active Directory and has ceased to support using the Azure Active Directory Graph API.
> Azure Active Directory no longer accepts user-supplied password values. Passwords are instead auto-generated by Azure and exported with the value attribute

## Assign the application to a role

To access resources in your subscription, you must assign the application to a role. Decide which role offers the right permissions for the application. To learn about the available roles, see RBAC: [Built in Roles](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles).

You can set the scope at the level of the subscription, resource group, or resource. Permissions are inherited to lower levels of scope. For example, adding an application to the Reader role for a resource group means it can read the resource group and any resources it contains. To allow the application to execute actions like reboot, start and stop instances, select the Contributor role.

```hcl
module "mod_service_principal" {
  source  = "azurenoops/overlays-service-principal/azuread"
  version = "x.x.x"
  
  # .... omitted
  # Adding roles and scope to service principal
  service_principal_assignments = [
    {
      scope                = "/subscriptions/xxxxx000-0000-0000-0000-xxxx0000xxxx"
      role_definition_name = "Contributor"
    },
  ]
}
```

## Assigning MSGraph Permissions

To set MsGraph permissions, you must specify a Microsoft Graph permission. See [Microsoft Graph Permissions Reference](https://learn.microsoft.com/en-us/graph/permissions-reference).

You must additionally set the type. If you are unsure, leave the type as "Scope".

```hcl

module "dsc_spn" {
    source  = "../terraform-azuread-overlays-service-principal/"

    service_principal_name = "service_principal"
    service_principal_description = "Service Principal that manages the M365DSC"

    enable_service_principal_certificate = false
    service_principal_password_rotation_in_years = 1


  # Adding Delegated Permission Grants
  service_principal_graph_permissions = [
    {
        id = "openid"
        type = "Scope"
    },
    {
        id = "User.Read"
        type = "Scope"
    },
  ]

}
```

## Assigning Directory Roles

To set the service principal directory roles, you must specify the role using the template id. For built-in roles, see [Azure AD Built-in Roles](https://learn.microsoft.com/en-us/azure/active-directory/roles/permissions-reference)

```hcl

module "dsc_spn" {
    source  = "../terraform-azuread-overlays-service-principal/"

    service_principal_name = "service_principal"
    service_principal_description = "Service Principal that manages the M365DSC"

    enable_service_principal_certificate = false
    service_principal_password_rotation_in_years = 1


  # Adding Directory Roles
  service_principal_directory_roles = [
    "fdd7a751-b60b-444a-984c-02652fe8fa1c", // Groups Administrator
    "4d6ac14f-3453-41d0-bef9-a3e0c569773a"
  ]
}

```