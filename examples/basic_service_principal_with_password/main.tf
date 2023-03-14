
module "mod_service_principal" {
  source = "../../"
  #source  = "azurenoops/overlays-service-principal/azuread"
  #version = "x.x.x"

  service_principal_name     = "dev-app-sp"
  service_principal_password_rotation_in_years = 1

  # Adding roles and scope to service principal
  service_principal_assignments = [
    {
      scope                = "/subscriptions/896f5276-df9a-4317-a791-469396bef7fa"
      role_definition_name = "Contributor"
    },
  ]
}
