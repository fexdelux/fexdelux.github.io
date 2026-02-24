#!/bin/bash

# Script para publicar o Helm Chart no repositório
# Uso: ./publish.sh

set -e

CHART_DIR="biend-wordpress-basic"
CHART_NAME="biend-wordpress-basic"
CHARTS_OUTPUT="../../../charts"
REPO_URL="https://fexdelux.github.io/charts"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Publicação do Helm Chart: ${CHART_NAME}${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# Verificar se o chart existe
if [ ! -d "$CHART_DIR" ]; then
    echo -e "${RED}❌ Erro: Diretório do chart não encontrado: $CHART_DIR${NC}"
    exit 1
fi

# Verificar se helm está instalado
if ! command -v helm &> /dev/null; then
    echo -e "${RED}❌ Erro: Helm não está instalado${NC}"
    echo "Instale o Helm: https://helm.sh/docs/intro/install/"
    exit 1
fi

echo -e "${YELLOW}📋 Etapa 1: Validando o chart...${NC}"
helm lint "$CHART_DIR"
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Erro no lint do chart. Corrija os erros antes de publicar.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Chart validado com sucesso!${NC}"
echo ""

# Obter versão do chart
CHART_VERSION=$(grep '^version:' "$CHART_DIR/Chart.yaml" | awk '{print $2}')
echo -e "${BLUE}📦 Versão do chart: ${CHART_VERSION}${NC}"
echo ""

# Verificar se o diretório de output existe
if [ ! -d "$CHARTS_OUTPUT" ]; then
    echo -e "${YELLOW}📁 Criando diretório de charts: $CHARTS_OUTPUT${NC}"
    mkdir -p "$CHARTS_OUTPUT"
fi

# Verificar se a versão já existe
if [ -f "$CHARTS_OUTPUT/${CHART_NAME}-${CHART_VERSION}.tgz" ]; then
    echo -e "${YELLOW}⚠️  Versão ${CHART_VERSION} já existe!${NC}"
    read -p "Deseja sobrescrever? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo -e "${RED}❌ Publicação cancelada.${NC}"
        echo -e "${YELLOW}Dica: Atualize a versão em Chart.yaml antes de publicar novamente.${NC}"
        exit 1
    fi
    rm -f "$CHARTS_OUTPUT/${CHART_NAME}-${CHART_VERSION}.tgz"
fi

echo -e "${YELLOW}📦 Etapa 2: Empacotando o chart...${NC}"
helm package "$CHART_DIR" -d "$CHARTS_OUTPUT"
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Erro ao empacotar o chart.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Chart empacotado: ${CHART_NAME}-${CHART_VERSION}.tgz${NC}"
echo ""

echo -e "${YELLOW}📋 Etapa 3: Atualizando índice do repositório...${NC}"
cd ../../..
if [ -f "charts/index.yaml" ]; then
    helm repo index charts/ --url "$REPO_URL" --merge charts/index.yaml
else
    helm repo index charts/ --url "$REPO_URL"
fi
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Erro ao atualizar o índice.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Índice atualizado: charts/index.yaml${NC}"
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Chart publicado com sucesso!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}📋 Próximos passos:${NC}"
echo ""
echo -e "  ${BLUE}1.${NC} Fazer commit das mudanças:"
echo -e "     ${GREEN}git add charts/${NC}"
echo -e "     ${GREEN}git commit -m \"chore: publish helm chart v${CHART_VERSION}\"${NC}"
echo ""
echo -e "  ${BLUE}2.${NC} Criar tag da versão:"
echo -e "     ${GREEN}git tag v${CHART_VERSION}${NC}"
echo ""
echo -e "  ${BLUE}3.${NC} Fazer push para o repositório:"
echo -e "     ${GREEN}git push origin main${NC}"
echo -e "     ${GREEN}git push --tags${NC}"
echo ""
echo -e "${YELLOW}🌐 Após o push, o chart estará disponível em:${NC}"
echo ""
echo -e "  ${BLUE}# Adicionar o repositório${NC}"
echo -e "  ${GREEN}helm repo add fexdelux ${REPO_URL}${NC}"
echo ""
echo -e "  ${BLUE}# Instalar o chart${NC}"
echo -e "  ${GREEN}helm install wordpress fexdelux/${CHART_NAME}${NC}"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
