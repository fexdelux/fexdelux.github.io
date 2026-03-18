# Correção de Problemas de Caracteres (^M)

## Problema Resolvido ✅

Ao instalar o chart Evolution API em servidores Linux/Kubernetes, apareciam caracteres `^M` nos arquivos YAML, causando erros de parsing.

### Causa
Arquivos criados/editados no Windows usam **CRLF** (`\r\n`) como line ending, enquanto Linux/Unix usam apenas **LF** (`\n`). O caractere `^M` representa o `\r` (carriage return).

### Solução Implementada

1. **Conversão automática no script de publicação**
   - O `publish.ps1` agora converte automaticamente CRLF → LF antes de empacotar
   - Veja: Etapa 1 do script

2. **Proteção via .gitattributes**
   - Arquivo `.gitattributes` criado para forçar LF nos commits
   - Garante que novos commits mantenham o padrão correto

3. **Conversão manual (se necessário)**
   ```bash
   cd support/helm/evolution-api
   find . -name "*.yaml" -o -name "*.yml" -o -name "*.tpl" | xargs sed -i 's/\r$//'
   ```

### Verificação

Para verificar se um arquivo está correto:
```bash
file values.yaml
```

**Correto**: `ASCII text` ou `UTF-8 text`  
**Incorreto**: `ASCII text, with CRLF line terminators`

### Status Atual

✅ Todos os arquivos convertidos para LF (Unix)  
✅ Script de publicação corrige automaticamente  
✅ .gitattributes protege commits futuros  
✅ Chart validado sem erros  
✅ Package republicado com correções  

### Arquivos Afetados

Todos os arquivos foram corrigidos:
- `*.yaml` - Configurações do chart
- `*.yml` - Valores e exemplos
- `*.tpl` - Templates do Helm
- `*.txt` - NOTES.txt
- `*.md` - Documentação

### Referências

- Issue original: Caracteres ^M no values.yaml
- Data da correção: 2026-03-18
- Versão do chart: 1.0.0
- Package atualizado: `charts/evolution-api-1.0.0.tgz`
