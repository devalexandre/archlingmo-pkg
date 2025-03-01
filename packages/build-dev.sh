#!/bin/bash
set -e

# Cores para saída
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

process_package() {
    local target=$1
    
    # Verifica se o diretório existe
    if [[ ! -d "$target" ]]; then
        echo -e "${YELLOW}Diretório $target não existe, pulando...${NC}"
        return
    fi
    
    # Verifica se já existem pacotes construídos
    if ls "$target"/*.pkg.tar.zst &> /dev/null; then
        echo -e "${GREEN}Pacote $target já construído, pulando...${NC}"
        return
    fi
    
    # Se não existir, faz o build
    echo -e "${YELLOW}Construindo pacote: $target${NC}"
    pushd "$target" > /dev/null
    
    # Verifica se a pasta src já existe
    if [ -d "src" ]; then
        echo -e "${YELLOW}Pasta src encontrada, pulando extração...${NC}"
        makepkg -ef --noconfirm  # -e pula a extração
    else
        makepkg -cf --noconfirm
    fi
    
    # Verifica se foram gerados pacotes e instala
    # if ls *.pkg.tar.zst &> /dev/null; then
    #     echo -e "${YELLOW}Instalando pacote(s) recém-construído(s)...${NC}"
    #     sudo pacman -U --noconfirm *.pkg.tar.zst
    #     echo -e "${GREEN}Pacote(s) instalado(s) com sucesso!${NC}"
    # fi
    
    popd > /dev/null
    
    echo -e "${GREEN}Pacote $target construído com sucesso!${NC}"
}

# Cria diretório de saída se não existir
mkdir -pv outputs

# Processa cada pacote listado no arquivo pkgs
while IFS= read -r target; do
    process_package "$target"
done < pkgs

# Move os pacotes construídos para o diretório outputs (excluindo pacotes de debug)
find . -type f -name "*.pkg.tar.zst" -not -name "*-debug-*.pkg.tar.zst" -exec bash -c '
    for file; do
        dest="outputs/$(basename "$file")"
        if [[ ! -f "$dest" ]]; then
            echo "Movendo $(basename "$file") para outputs/"
            mv "$file" outputs/
        else
            echo "Arquivo $dest já existe, pulando"
        fi
    done
' bash {} +

echo -e "${YELLOW}Pacotes de debug não foram movidos para o diretório outputs${NC}"

echo -e "${GREEN}Processo de build concluído!${NC}"
