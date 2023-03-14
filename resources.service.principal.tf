# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

resource "azuread_application" "app" {
  display_name     = var.service_principal_name
  identifier_uris  = var.identifier_uris
  owners           = [data.azuread_client_config.current.object_id]
  sign_in_audience = var.sign_in_audience
}

resource "azuread_service_principal" "sp" {
  application_id    = azuread_application.app.application_id
  owners            = [data.azuread_client_config.current.object_id]
  alternative_names = var.alternative_names
  description       = var.service_principal_description
}





