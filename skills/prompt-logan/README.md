# /prompt-logan

Transforma um pedido solto ("quero um filtro de vencidos na tela de cobranças") num prompt
fechado para um agente de código, com critérios de aceite numerados que cobrem o pedido
inteiro.

Antes de escrever, a skill abre a sua aplicação no navegador, confere cada frase do pedido
contra a tela, pergunta o que estiver em aberto e, quando o pedido mexe em interface, monta
uma maquete na própria página para você aprovar. Nada é inventado: cada linha do prompt vem
das suas palavras, do que foi visto na tela, de um `arquivo:linha` ou de uma resposta sua.

## Instalar

Cole isto no Claude Code e envie:

```text
Instale a skill "prompt-logan" do repositório https://github.com/escolaparaprogramadores/claude-skills para todos os meus projetos: copie a pasta skills/prompt-logan (com os arquivos de dentro) para a pasta de skills do meu usuário (~/.claude/skills/prompt-logan). Se ela já existir, me pergunte antes de substituir. No fim, me mostre os arquivos instalados.
```

Outros jeitos de instalar estão no [README principal](../../README.md#instalação).

## Como usar

```text
/prompt-logan adicionar a opção "Vencido" no filtro Situação da tela de cobranças
```

Deixe a aplicação aberta e logada no navegador antes de chamar.

## O que ela entrega

| Onde | O quê |
|---|---|
| na conversa | um bloco de texto pronto para colar no agente que vai implementar |
| em disco | o pedido original, o script da maquete aprovada, os prints e o prompt final |

A pasta de provas é `.prompt-provas/<data>-<feature>/` na raiz do projeto. Para guardar em
outro lugar, defina a variável de ambiente `PROMPT_PROVAS_DIR`.

## Requisitos

| Para | Precisa de |
|---|---|
| navegar e montar a maquete | Claude Code com a extensão [Claude in Chrome](https://claude.com/claude-in-chrome) (recomendada, porque aproveita o seu login) ou o navegador embutido do app de desktop |
| print em disco no Windows | Windows PowerShell 5.1 ou PowerShell 7 |
| print em disco no macOS/Linux | `bash` e uma destas: `screencapture`, `grim`, `gnome-screenshot`, `import` ou `scrot` |

> [!IMPORTANT]
> No macOS, dê ao terminal a permissão **Gravação de Tela** (Ajustes do Sistema → Privacidade e
> Segurança). Sem ela, o `screencapture` grava só o papel de parede e o print sai errado.
>
> O script de print fotografa a tela inteira. Esconda o que não deve aparecer antes de rodar.

## Arquivos

| Arquivo | Para quê |
|---|---|
| `SKILL.md` | as instruções que o Claude segue |
| `scripts/capturar-tela.ps1` | print da tela no Windows |
| `scripts/capturar-tela.sh` | print da tela no macOS e no Linux |
