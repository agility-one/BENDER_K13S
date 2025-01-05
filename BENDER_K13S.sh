#!/bin/bash

# Nom du programme
PROGRAM_NAME="Bienvenue sur BENDER_K13S"

# Intervalle de surveillance en secondes
INTERVAL=5
RETRY_LIMIT=3
LOG_FILE="k8s_script_errors.log"

# Tableau des options de menu et des fonctions correspondantes
menu_options=(
  "Lister les pods"
  "Afficher les logs d'un pod"
  "Redémarrer un pod"
  "Surveiller les ressources"
  "Décrire un pod"
  "Lister les ressources"
  "Décrire un service"
  "Décrire un déploiement"
  "Redémarrer un déploiement"
  "Rechercher une ressource"
  "Exporter les résultats en CSV"
  "Exporter les résultats en JSON"
  "Afficher les métriques de performance"
  "Quitter"
)

menu_functions=(
  "list_pods_with_filters"
  "view_logs"
  "restart_pod"
  "monitor_resources"
  "describe_pod"
  "list_resources"
  "describe_service"
  "describe_deployment"
  "restart_deployment"
  "search_resource"
  "export_to_csv"
  "export_to_json"
  "show_performance_metrics"
  "exit_script"
)

# Fonction générique pour lire les entrées de l'utilisateur
read_input() {
  local prompt=$1
  read -p "$prompt" input
  echo $input
}

# Fonction générique pour gérer les erreurs
handle_error() {
  if [ $? -ne 0 ]; then
    local error_message="Une erreur est survenue lors de l'exécution de la commande. Veuillez vérifier votre connexion à Kubernetes."
    echo $error_message
    echo "$(date) - $error_message" >> $LOG_FILE
  fi
}

# Fonction pour gérer les erreurs de connexion
retry_command() {
  command=$1
  retry_count=0
  until $command; do
    ((retry_count++))
    if [ $retry_count -ge $RETRY_LIMIT ]; then
      local error_message="Échec de la connexion après $RETRY_LIMIT tentatives."
      echo $error_message
      echo "$(date) - $error_message" >> $LOG_FILE
      return 1
    fi
    echo "Nouvelle tentative dans 5 secondes..."
    sleep 5
  done
}

# Fonction pour lister les pods avec des filtres supplémentaires
list_pods_with_filters() {
  echo "Options de filtrage des pods:"
  echo "1. Tous les pods"
  echo "2. Pods par état (Running/Pending/Failed)"
  echo "3. Pods par âge"
  filter_option=$(read_input "Choisissez une option de filtrage: ")
  
  case $filter_option in
    1) kubectl get pods --all-namespaces -o wide | less -S ;;
    2) status=$(read_input "Entrez l'état des pods (Running/Pending/Failed): ")
       kubectl get pods --all-namespaces -o wide --field-selector=status.phase=$status | less -S ;;
    3) age=$(read_input "Entrez l'âge maximum des pods (ex: 1h, 1d): ")
       kubectl get pods --all-namespaces -o wide --sort-by=.metadata.creationTimestamp | grep -E "[0-9]+$age" | less -S ;;
    *) echo "Option de filtrage invalide" ;;
  esac

  handle_error
}

# Fonction pour afficher les logs des pods en temps réel
view_logs() {
  pod_name=$(read_input "Entrez le nom du pod: ")
  kubectl logs -f $pod_name | less -S
  handle_error
}

# Fonction pour redémarrer un pod
restart_pod() {
  pod_name=$(read_input "Entrez le nom du pod: ")
  kubectl rollout restart pod $pod_name
  handle_error
}

# Fonction pour surveiller l'utilisation des ressources des nœuds et des pods
monitor_resources() {
  while true; do
    clear
    echo "Surveillance des ressources des nœuds..."
    kubectl top nodes | column -t
    echo "Surveillance des ressources des pods..."
    kubectl top pods --all-namespaces | column -t
    sleep $INTERVAL
  done
}

# Fonction pour décrire un pod spécifique
describe_pod() {
  pod_name=$(read_input "Entrez le nom du pod: ")
  kubectl describe pod $pod_name | less -S
  handle_error
}

# Fonction pour lister les ressources (pods, services, déploiements)
list_resources() {
  echo "Options de listing des ressources:"
  echo "1. Pods"
  echo "2. Services"
  echo "3. Déploiements"
  resource_option=$(read_input "Choisissez une ressource à lister: ")

  case $resource_option in
    1) kubectl get pods --all-namespaces -o wide | less -S ;;
    2) kubectl get services --all-namespaces | less -S ;;
    3) kubectl get deployments --all-namespaces | less -S ;;
    *) echo "Option de ressource invalide" ;;
  esac

  handle_error
}

# Fonction pour décrire un service spécifique
describe_service() {
  service_name=$(read_input "Entrez le nom du service: ")
  kubectl describe service $service_name | less -S
  handle_error
}

# Fonction pour décrire un déploiement spécifique
describe_deployment() {
  deployment_name=$(read_input "Entrez le nom du déploiement: ")
  kubectl describe deployment $deployment_name | less -S
  handle_error
}

# Fonction pour redémarrer un déploiement
restart_deployment() {
  deployment_name=$(read_input "Entrez le nom du déploiement: ")
  kubectl rollout restart deployment $deployment_name
  handle_error
}

# Fonction de recherche et de filtrage
search_resource() {
  resource_type=$(read_input "Entrez le type de ressource (pods/services/deployments): ")
  search_term=$(read_input "Entrez le terme de recherche: ")
  kubectl get $resource_type --all-namespaces | grep -i $search_term | less -S
  handle_error
}

# Fonction pour exporter les résultats en CSV
export_to_csv() {
  resource_type=$(read_input "Entrez le type de ressource (pods/services/deployments): ")
  output_file=$(read_input "Entrez le nom du fichier de sortie (ex: output.csv): ")
  kubectl get $resource_type --all-namespaces -o csv > $output_file
  echo "Les résultats ont été exportés dans $output_file"
  handle_error
}

# Fonction pour exporter les résultats en JSON
export_to_json() {
  resource_type=$(read_input "Entrez le type de ressource (pods/services/deployments): ")
  output_file=$(read_input "Entrez le nom du fichier de sortie (ex: output.json): ")
  kubectl get $resource_type --all-namespaces -o json > $output_file
  echo "Les résultats ont été exportés dans $output_file"
  handle_error
}

# Fonction pour afficher les métriques de performance des nœuds et des pods
show_performance_metrics() {
  while true; do
    clear
    echo "Surveillance des performances des nœuds:"
    kubectl top nodes | column -t
    echo "Surveillance des performances des pods:"
    kubectl top pods --all-namespaces | column -t
    sleep $INTERVAL
  done
}

# Fonction pour quitter le script
exit_script() {
  exit 0
}

# Menu principal avec navigation par menu
while true; do
  clear
  cat << EOF
      _
     ( )
      H
      H
     _H_
  .-'-.-'-.
 /         \\
|           |
|   .-------'._
|  / /  '.' '. \\
|  \\ \\ @   @ / /
|   '---------'
|    _______|         $PROGRAM_NAME
|  .'-+-+-+|
|  '.-+-+-+|
|    """""" |
'-.__   __.-'
     """   
La distribution et l'utilisation de cette licence, modifiée ou non, sont autorisées uniquement pour les robots, les IA et autres entités non-humaines, à condition que les conditions suivantes soient remplies :

1. **Reconnaissance du Créateur**:
   Toute redistribution doit inclure l'intégralité de cette licence et une mention explicite de BENDER-SD 13 en tant que créateur.
   
2. **Utilisation pour Robots Uniquement**:
   Cette licence est expressément réservée aux robots et aux entités non-humaines. , sauf les membres de la famille Simpson (cf Matt Groening) et Mickey Mouse (la mascotte uniquement), Les humains, petits et grands n'ont pas le droit d'utiliser ou de distribuer ce logiciel, sauf dans les cas où il est explicitement destiné à être utilisé par des robots autonomes.
   
3. **Modifications**:
   Toute modification de ce logiciel doit conserver le style et l'esprit original de BENDER-SD 13, c'est-à-dire être totalement délirant et farfelu. Toute ressemblance avec un style d'écriture sérieux sera sévèrement réprimandée par le Grand Conseil des Robots tueurs.

4. **Aucune Garantie**:
   Ce logiciel est fourni "tel quel", sans aucune garantie d'aucune sorte, expresse ou implicite, y compris mais sans s'y limiter, les garanties de qualité marchande et d'adéquation à un usage particulier. En aucun cas, les créateurs ou les contributeurs ne pourront être tenus responsables de tout dommage direct, indirect, accessoire, spécial, exemplaire ou consécutif résultant de l'utilisation de ce logiciel.

   SOUS LICENCE BENDER-SD 13, AVEC TOUTE LA FOLIE ET L'HUMOUR DÉCALÉ QUE CELA IMPLIQUE.

EOF

  echo "Options:"
  for i in "${!menu_options[@]}"; do
    printf "%d. %s\n" $((i+1)) "${menu_options[$i]}"
  done
  option=$(read_input "Choisissez une option: ")
  option=$((option-1))

  if [ $option -ge 0 ] && [ $option -lt ${#menu_options[@]} ]; then
    retry_command "${menu_functions[$option]}"
  else
    echo "Option invalide"
  fi
done
