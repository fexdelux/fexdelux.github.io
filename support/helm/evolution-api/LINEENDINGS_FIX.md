# CorreÃ§Ã£o de Problemas de Caracteres (^M)

## Problema Resolvido âœ…

Ao instalar o chart Evolution API em servidores Linux/Kubernetes, apareciam caracteres `^M` nos arquivos YAML, causando erros de parsing.

### Causa
Arquivos criados/editados no Windows usam **CRLF** (`\r\n`) como line ending, enquanto Linux/Unix usam apenas **LF** (`\n`). O caractere `^M` representa o `\r` (carriage return).

### SoluÃ§Ã£o Implementada

1. **ConversÃ£o automÃ¡tica no script de publicaÃ§Ã£o**
   - O `publish.ps1` agora converte automaticamente CRLF â†’ LF antes de empacotar
   - Veja: Etapa 1 do script

2. **ProteÃ§Ã£o via .gitattributes**
   - Arquivo `.gitattributes` criado para forÃ§ar LF nos commits
   - Garante que novos commits mantenham o padrÃ£o correto

3. **ConversÃ£o manual (se necessÃ¡rio)**
   ```bash
   cd support/helm/evolution-api
   find . -name "*.yaml" -o -name "*.yml" -o -name "*.tpl" | xargs sed -i 's/\r$//'
   ```

### VerificaÃ§Ã£o

Para verificar se um arquivo estÃ¡ correto:
```bash
file values.yaml
```

**Correto**: `ASCII text` ou `UTF-8 text`  
**Incorreto**: `ASCII text, with CRLF line terminators`

### Status Atual

âœ… Todos os arquivos convertidos para LF (Unix)  
âœ… Script de publicaÃ§Ã£o corrige automaticamente  
âœ… .gitattributes protege commits futuros  
âœ… Chart validado sem erros  
âœ… Package republicado com correÃ§Ãµes  

### Arquivos Afetados

Todos os arquivos foram corrigidos:
- `*.yaml` - ConfiguraÃ§Ãµes do chart
- `*.yml` - Valores e exemplos
- `*.tpl` - Templates do Helm
- `*.txt` - NOTES.txt
- `*.md` - DocumentaÃ§Ã£o

### ReferÃªncias

- Issue original: Caracteres ^M no values.yaml
- Data da correÃ§Ã£o: 2026-03-18
- VersÃ£o do chart: 1.0.0
- Package atualizado: `charts/evolution-api-1.0.0.tgz`
