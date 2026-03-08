module "labels" {
  source    = "cloudposse/label/null"
  version   = "0.25.0"
  
  namespace = "univ"        # Абревіатура універу
  stage     = "lab1"        # Етап
  name      = "course-app"  # Назва проекту
  delimiter = "-"

  tags = {
    "Project" = "CloudTechnologies"
    "Owner"   = "YourName"
  }
}