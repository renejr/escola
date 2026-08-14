#!/bin/bash

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Conectando à VPS para extrair configurações do Nginx...${NC}"

# Executa SSH e salva o output no arquivo nginx_current.txt local
ssh -p 22022 root@108.174.148.255 "echo '=== /etc/nginx/nginx.conf ===' && cat /etc/nginx/nginx.conf && echo -e '\n=== /etc/nginx/sites-enabled/* ===' && cat /etc/nginx/sites-enabled/*" > nginx_current.txt

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Configurações extraídas com sucesso e salvas em nginx_current.txt localmente.${NC}"
else
    echo -e "${YELLOW}Aviso: Houve algum erro ao tentar extrair as configurações ou a conexão falhou.${NC}"
fi
