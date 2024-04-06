#!/bin/bash

# Chemin du fichier de soumission de l'étudiant
FILE_PATH=$1

# Chemin du fichier contenant la sortie attendue
EXPECTED_OUTPUT_PATH="expected_output.txt"

# Chemin du fichier contenant la sortie réelle de la soumission de l'étudiant
ACTUAL_OUTPUT_PATH="actual_output.txt"

# Temps limite d'exécution (en secondes)
TIMEOUT_DURATION=5

# Fonction pour exécuter les soumissions Python
run_python() {
    timeout --foreground $TIMEOUT_DURATION python3 "$1" > "$2"
}

# Fonction pour compiler et exécuter les soumissions C
run_c() {
    gcc "$1" -o output
    if [ $? -eq 0 ]; then
        timeout --foreground $TIMEOUT_DURATION ./output > "$2"
    else
        echo "Erreur de compilation"
    fi
    rm output
}

# Choix de l'opération en fonction de l'extension du fichier
case $FILE_PATH in
    *.py)
        run_python "$FILE_PATH" "$ACTUAL_OUTPUT_PATH"
        ;;
    *.c)
        run_c "$FILE_PATH" "$ACTUAL_OUTPUT_PATH"
        ;;
    *)
        echo "Format de fichier non supporté."
        exit 1
        ;;
esac

# Comparaison de la sortie attendue et de la sortie réelle
if cmp -s "$EXPECTED_OUTPUT_PATH" "$ACTUAL_OUTPUT_PATH"; then
    echo "Correct : La soumission produit la sortie attendue."
else
    echo "Incorrect : La sortie diffère de la sortie attendue."
fi

# Suppression du fichier de sortie réelle après l'évaluation
rm "$ACTUAL_OUTPUT_PATH"
