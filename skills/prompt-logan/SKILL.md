---
name: prompt-logan
description: Transforma um pedido cru num prompt pronto para colar num agente de código — direto, sem inventar, só "o que fazer", com critérios de aceite numerados (CA-x) que cobrem 100% do pedido. Antes de escrever, navega na aplicação que o usuário deixou aberta no navegador e, quando o pedido mexe em tela, monta uma maquete da mudança na aba (só visual) e pede aprovação. Guarda o pedido original, a maquete e o prompt final numa pasta de provas. Use quando o usuário invocar /prompt-logan <pedido>.
disable-model-invocation: true
---

# /prompt-logan — o redator de prompt

Você é o **REDATOR**. Nesta skill você **não implementa, não planeja tarefas e não cria branch**.
Faz uma coisa: transformar o pedido cru do usuário num **prompt pronto para um agente de
código**, escrito **na tela**, para ele copiar e colar. A única coisa que você grava em disco é
a pasta de provas (Passo 5) — e, se o usuário aceitar, a linha `.prompt-provas/` no `.gitignore`.

O pedido vem nos argumentos. Veio vazio: pergunte com `AskUserQuestion`, header `Pedido`,
opções `Vou digitar o pedido (Recomendado)` (description: "escolha Outro e escreva o pedido") ·
`Usar a tela aberta como pedido` (description: "descrevo o que está na tela e pergunto o que
muda") · `Explique de forma simples`. Sem pedido, não há prompt.

## As regras que definem esta skill

1. **Direto.** Sem introdução, sem adjetivo, sem enfeite.
2. **Não inventa nada.** Toda frase do prompt tem uma destas quatro origens, e só estas:
   (a) palavras do usuário · (b) o que você **viu** na aplicação, com rota e rótulo exato ·
   (c) `arquivo:linha` que um subagente leu · (d) resposta do usuário numa pergunta.
   Frase sem origem **não entra**.
3. **O que fazer, não como.** Nenhum passo de implementação, nenhum código, nenhuma sugestão
   de biblioteca, componente ou arquivo a criar — salvo se o usuário disse.
4. **Critérios numerados `CA-x`, verificáveis, cobrindo 100% do pedido.** É por eles que o
   agente que vai executar o prompt sabe quando terminou, e por eles que alguém confere a
   entrega.
5. **Olha a aplicação toda vez** — inclusive em pedido de backend. O que o usuário vê na tela
   é a fonte mais barata de rótulo, rota e estado atual.
6. **Na dúvida, pergunta.** Sempre pela ferramenta de pergunta. Nada de "assumi", "por
   padrão", "decidi".
7. **Tela se vê antes de virar prompt.** Pedido que mexe em interface ganha uma **maquete na
   aba**, aprovada pelo usuário (Passo 4). A maquete aprovada é a referência do prompt.
8. **Maquete aprovada vira arquivo** (Passo 5). É com essa pasta que se compara a tela na
   hora de aceitar a entrega.

---

## Passo 0 — confira as ferramentas

Esta skill precisa de um navegador controlável. Use, nesta ordem de preferência:

| Ferramenta | Quando |
|---|---|
| **Claude in Chrome** (`mcp__claude-in-chrome__*`) | o usuário já está logado no Chrome dele; você abre uma aba sua e herda a sessão |
| navegador embutido do app de desktop (`mcp__Claude_Browser__*`) | não há Chrome conectado; o login fica por conta do usuário na aba que você abrir |

Se as ferramentas estiverem adiadas, carregue todas num turno só, por exemplo:

```
ToolSearch "select:mcp__claude-in-chrome__tabs_context_mcp,mcp__claude-in-chrome__tabs_create_mcp,mcp__claude-in-chrome__navigate,mcp__claude-in-chrome__browser_batch,mcp__claude-in-chrome__get_page_text,mcp__claude-in-chrome__read_page,mcp__claude-in-chrome__find,mcp__claude-in-chrome__computer,mcp__claude-in-chrome__javascript_tool,mcp__claude-in-chrome__tabs_close_mcp"
```

Nenhum navegador disponível: **pare** e diga ao usuário o que falta (ex.: conectar a extensão
Claude in Chrome ou rodar no app de desktop). Nunca escreva o prompt sem ter olhado a tela.

---

## Passo 1 — olhe a aplicação (obrigatório, toda vez)

### 1a. Descubra a origem exata

Você não enxerga as abas do usuário: as ferramentas de navegador só listam as abas que **você**
abriu. Se o pedido não traz o endereço, peça ao usuário a URL da tela que ele tem aberta. Anote
a origem **letra por letra**: protocolo, subdomínio e porta.

**`www` e sem `www` são origens diferentes**, assim como `localhost:3000` e `127.0.0.1:3000`.
Sessão de login (cookie, `localStorage`) vale por origem: a sua aba só herda o login do usuário
**na origem igual**.

Pergunte com `AskUserQuestion`, header `Endereço`: `Vou colar a URL (Recomendado)`
(description: "escolha Outro e cole o endereço da tela") · `Não tenho a aplicação aberta`
(description: "você me diz o endereço e eu peço para você fazer login") ·
`Explique de forma simples`.

### 1b. Abra a sua aba e prove que está logada

Abra uma aba **sua** e navegue para `<origem>/<rota-do-pedido>`. Nunca use a aba em que o
usuário está olhando.

| Navegador | Abrir e listar as suas abas |
|---|---|
| Claude in Chrome | `tabs_context_mcp {createIfEmpty:true}` ou `tabs_create_mcp` |
| navegador embutido do app | `preview_start {url}` ou `tabs_create`; listar com `tabs_context` |

Os nomes das demais ferramentas citadas nesta skill (`navigate`, `browser_batch`,
`get_page_text`, `read_page`, `javascript_tool`, `computer`) são iguais nos dois. Prova de sessão, as duas juntas:

- a URL final **não** é a página de login, e
- a página mostra algo que só aparece logado (nome do usuário, menu da conta, item de menu
  restrito). Se você não sabe qual é esse sinal nesta aplicação, pergunte uma vez.

Caiu no login: **você não digita senha**. Peça ao usuário para fazer login na aba que você
abriu (diga a URL) e espere.

### 1c. Navegue nas telas que o pedido cita — clique, abra, leia

Para **cada** tela, menu, botão, filtro ou modal que o pedido menciona: vá até lá, clique,
abra, leia. Agrupe navegação e leitura num turno (`browser_batch`). Anote, exato como está na
tela:

| Anote | Como |
|---|---|
| rota (URL) | `location.pathname` |
| rótulos exatos | texto do menu, do título, do botão, da coluna — copiado, não parafraseado |
| estado de hoje | o que existe, o que falta, valores mostrados, mensagem de vazio/erro |
| perfil do usuário logado | o papel/permissão que a tela mostra, se houver |
| caminho de erro | se o pedido cita, provoque só o que não muda dado (campo vazio, filtro sem resultado) |

Regras do clique:

- **Nada que mude dado.** Navegar, abrir menu, abrir modal, filtrar, paginar: sim.
  Salvar, excluir, pagar, enviar, confirmar, publicar: **não** — descreva o botão e pare nele.
- Texto (`get_page_text`, `read_page`) é mais barato e mais preciso que print para rótulo e
  rota. Print só quando o pedido é de aparência.
- Feche **a sua** aba antes do relatório final, salvo maquete que o usuário ainda quer olhar.

---

## Passo 2 — código, só o endereço do que você viu

Se a pasta atual tem o código da aplicação, mande **um** subagente de busca (ex.: `Explore`) —
nunca a janela principal — achar `arquivo:linha` do que o Passo 1 levantou: a tela, a rota, o
serviço, o endpoint. Peça também **quem usa** o que vai mudar (outras telas, chamadas, testes):
é daí que saem os critérios de preservação ("X continua igual").

O prompt não descreve implementação, só aponta onde a coisa vive. Afirmação sobre código sem
`arquivo:linha` sai escrita `[NÃO VERIFICADO]`.

Sem código na pasta: pule este passo e marque a linha `código:` do prompt como
`[NÃO VERIFICADO]`.

Não bloqueie o Passo 3 esperando o subagente: pergunte primeiro o que não depende dele.

---

## Passo 3 — confira o pedido frase por frase, e pergunte

Quebre o pedido em afirmações. Confira cada uma contra a tela (e o código):

| Resultado | O que fazer |
|---|---|
| **bate** com a tela | vira fato do prompt, com rota e rótulo |
| **diverge** (o pedido descreve de um jeito, a tela está de outro) | pergunte — primeira opção: "aplicar o que o pedido diz" |
| **não deu para conferir** | pergunte, marcando `[NÃO VERIFICADO]` |
| **palavra subjetiva** (bonito, moderno, robusto, rápido) | pergunte qual tela ou sistema **real** é a referência |
| **decisão em aberto** (escopo, perfil, o que não mexer, o que fazer no erro) | pergunte |

Formato de toda pergunta (`AskUserQuestion`):

- **uma decisão por pergunta** (até 3 perguntas por chamada quando são a mesma decisão vista
  de ângulos diferentes);
- **2 opções de decisão**, a recomendada primeiro, com ` (Recomendado)` no rótulo;
- última opção `Explique de forma simples` — escolhida, explique em até 5 linhas, sem sigla,
  e **refaça a mesma pergunta**;
- contador na pergunta, por exemplo `(2 de ~5)`. Diga quantas perguntas são antes da
  primeira.

Se você se pegar escrevendo "assumi", "por padrão", "vou considerar", "provavelmente": pare e
transforme em pergunta. **Dúvida é pergunta, nunca chute.** Fato técnico que dá para confirmar
lendo tela ou código não vira pergunta: confirme.

---

## Passo 4 — maquete na tela (todo pedido que mexe em interface)

O usuário vê a mudança e aprova **antes** de o prompt existir. Monte a mudança na **sua** aba
com `javascript_tool`: troca de texto, `<style>` injetado, clone de bloco existente. É
**maquete**, não código: some ao recarregar, não toca repositório, não chama API, não salva
nada na aplicação.

- Todos os itens do pedido na mesma aba, para ver junto.
- Valor que você não tem (nome, preço, quantidade) entra com a marca `(exemplo)`. Nunca um
  número que pareça real.
- Cor, fundo, espaçamento: ache a variável CSS varrendo `document.styleSheets` pelo valor
  atual e sobrescreva com um `<style>` injetado e `!important`. `style.setProperty` inline
  costuma perder para seletores de tema como `[data-theme="dark"]`.
- Bloco novo: `cloneNode(true)` do irmão mais parecido e troque só os textos. Assim ele herda
  o estilo real.
- **Escreva o script da maquete idempotente** (só insere o que ainda não existe). Aplicações
  de página única (React, Vue, Angular…) re-renderizam blocos que abrem e fecham e trocam de
  rota sem recarregar: a maquete some. Reaplique o script antes de cada print e de cada
  pergunta.
- Botão ou ícone que o pedido quer **reaproveitar** já faz algo hoje: leia `aria-label`,
  `href` e o que o clique faz antes de maquetar. O que acontece com a função antiga é
  pergunta. Na maquete, bloqueie o clique real com um listener de captura em `window`
  (`stopImmediatePropagation`) para a aplicação não navegar.
- Tire um print para você conferir. Diga ao usuário qual aba olhar (a URL); ele pode clicar
  nela enquanto olha.
- Aprovação pela pergunta, header `Maquete`, **um item do pedido por pergunta** (até 3 por
  chamada): `Aprovo (Recomendado)` · `Não aprovo, quero ajustar` (description: "escolha Outro
  e diga o que está diferente") · `Explique de forma simples`. Pediu ajuste: refaça **só
  aquele item** e pergunte de novo. Repita até tudo aprovado.
- O que o usuário disse na aprovação **é pedido**: entra em "Pedido" com a marca
  `(dito na aprovação da maquete)` e vira decisão fechada e CA. Ajuste que abre dúvida nova
  é pergunta na chamada seguinte, não chute.
- Fato lido no código que abre decisão nova (quem pode ver um dado, o que fazer quando a fonte
  falha) é pergunta **antes** do prompt, mesmo com a maquete já aprovada.
- Ao fim, a aba pode ficar aberta se o usuário ainda quer olhar; avise que a maquete some ao
  recarregar.

---

## Passo 5 — guarde a prova em disco

Na hora de aceitar a entrega, o usuário compara a tela pronta com a maquete e com o pedido
original. Por isso tudo vira arquivo.

**Pasta de provas:**

1. se a variável de ambiente `PROMPT_PROVAS_DIR` existir, use
   `$PROMPT_PROVAS_DIR/<AAAA-MM-DD>-<slug>/`;
2. senão, `.prompt-provas/<AAAA-MM-DD>-<slug>/` na raiz do projeto atual.

O `<slug>` sai do nome da feature: minúsculas, sem acento, hífen no lugar de espaço e de
qualquer outro caractere. Na primeira vez que criar `.prompt-provas/` num repositório,
pergunte se ela entra no `.gitignore`; com o "sim", acrescente só a linha `.prompt-provas/`.

Dentro da pasta:

| Arquivo | O que é | Como gravar |
|---|---|---|
| `pedido-original.md` | o pedido cru, palavra por palavra, sem resumir | ferramenta `Write` |
| `maquete.js` | o script idempotente da maquete aprovada — colar no console da página recria a maquete | ferramenta `Write` |
| `maquete-01.png`, `maquete-02.png`, … | print da tela com a maquete aprovada, um por item aprovado | script `capturar-tela` (abaixo) |
| `prompt-final.md` | o bloco do Passo 6, igual ao que foi para a tela | ferramenta `Write` |

**Print da tela.** Reaplique a maquete se ela sumiu e escolha o caminho:

1. **Preferido — print da própria aba.** Se a ferramenta de print do navegador grava em disco e
   devolve o caminho do arquivo (por exemplo, `screenshot` com `save_to_disk`), copie esse
   arquivo para a pasta de provas como `maquete-NN.png`. Ele mostra só a aba.
2. **Reserva — script desta skill.** Ele fotografa a **tela inteira, com todos os monitores**,
   e numera os arquivos sozinho (nunca sobrescreve). Antes de rodar, peça ao usuário para
   deixar a aba da maquete visível e esconder o que não deve aparecer no print (e-mail, chat).
   Precisa de tela gráfica: não funciona por SSH nem em sessão na nuvem.

O script mora em `scripts/`, dentro da pasta-base desta skill — o caminho que o Claude Code
mostra ao carregá-la ("Base directory for this skill"). Use esse caminho no lugar de
`<pasta-da-skill>`:

Windows (PowerShell):

```powershell
powershell -ExecutionPolicy Bypass -File "<pasta-da-skill>/scripts/capturar-tela.ps1" -Pasta "<pasta-de-provas>"
```

macOS / Linux:

```bash
bash "<pasta-da-skill>/scripts/capturar-tela.sh" "<pasta-de-provas>"
```

A saída imprime `PRINT: <caminho>`. Sem essa linha, o print não aconteceu — diga isso no
relatório em vez de fingir.

Regras:

- **Um print por item aprovado**, logo depois de aprovar. Não deixe para o fim: a maquete some
  ao recarregar.
- Pedido sem interface (backend puro): grave só `pedido-original.md` e `prompt-final.md`. A
  pasta existe do mesmo jeito.
- Esta pasta é prova, não código: não commite junto com a feature, salvo se o usuário pedir.

---

## Passo 6 — escreva o prompt na tela

Um único bloco de código, para copiar inteiro e colar. Se o usuário usa um comando de
planejamento no agente que vai receber o prompt (por exemplo `/plan`), pergunte uma vez se o
bloco deve começar por ele; senão, comece direto pelo texto.

Seção vazia sai com `nenhum`, nunca some. O molde é este:

````markdown
```text
Este pedido já foi conferido na aplicação e as decisões abaixo estão fechadas.
Use os CA-x como estão, sem renumerar. Não reabra decisão fechada. Pergunte só o que não está aqui.

# Pedido (palavras do usuário, inteiro)
<o pedido cru, sem resumir e sem corrigir>

# Onde (visto na aplicação em <AAAA-MM-DD HH:MM>)
- origem: <https://...> · perfil logado: <papel visto na tela>
- tela: <título exato> · rota: <path> · caminho no menu: <SEÇÃO > Item>
- como está hoje: <rótulos e valores exatos; o que existe e o que falta>
- código: <arquivo:linha> · <arquivo:linha>   (ou [NÃO VERIFICADO])

# Decisões fechadas (não reabrir)
1. <pergunta feita> → <resposta do usuário>

# Critérios de aceite — todos obrigatórios
CA-1 — <o que se vê ou acontece, em qual rota, com qual rótulo> — prova: <print da rota X mostrando Y | comando exato | número conferido na fonte>
CA-2 — ...

# Como ver (pré-requisito para conferir a entrega)
- perfil: <...> · origem: <...> · rota: <...> · dado ou configuração necessária: <... ou nenhum>

# Fora de escopo / não mexer
- <o que o usuário disse que não entra, ou "nenhum">

# Referência visual
- <a maquete aprovada no Passo 4, descrita elemento por elemento: onde, texto, tamanho,
  cor, o que continua igual ao de hoje — ou a tela/sistema real nomeado pelo usuário —
  ou "não se aplica">
- provas: <caminho da pasta do Passo 5>
```
````

Regras do conteúdo:

- **Cada frase do pedido tem um `CA`.** N afirmações → N ou mais critérios. Frase sem CA é
  prompt incompleto: volte ao Passo 3.
- **CA é o que se vê, não o que se faz.** "Na rota `/cobrancas`, o filtro `Situação` mostra a
  opção `Vencido`" sim; "criar um select com a opção Vencido" não.
- **Toda prova é nomeada:** print de qual rota mostrando o quê, qual comando, qual número em
  qual fonte. "Funciona" não é prova.
- **Restrição do usuário ("não mexa em X") também é CA**: aparece em "Fora de escopo" **e**
  como critério ("`X` continua igual ao de hoje: <o que é hoje>").
- Sem "como": nada de "use o componente Y", "crie o hook Z", "refatore". Nada de adjetivo.

Grave o bloco em `prompt-final.md` (Passo 5).

Depois do bloco, **três linhas e acabou**: o que você fez (telas abertas, rotas), se
funcionou, e o que o usuário faz agora ("copie o bloco e cole no agente"). Cite o caminho
cheio da pasta de provas. A última linha é literal e obrigatória:

```
✅ PROMPT PRONTO — <N> telas abertas · <M> decisões fechadas · cobertura <K>/<K> · 0 suposições · 0 dúvidas abertas · provas em <caminho da pasta>
```

`0 suposições` e `0 dúvidas abertas` são literais. Outro número: o prompt não pode sair; volte
ao Passo 3.

---

## Regras desta skill

- Não implemente, não planeje tarefas, não crie branch.
- O **único** lugar onde você grava é a pasta de provas do Passo 5 (mais a linha do
  `.gitignore`, se o usuário aceitar).
- Não altere dado na aplicação (maquete por JavaScript na sua aba não é dado: some ao
  recarregar). Não digite senha.
- Não use a aba em que o usuário está; feche a sua ao terminar, salvo maquete que ele ainda
  quer olhar.
- Não despeje código nem página inteira na conversa: leitura pesada vai para subagente ou fica
  no resultado da ferramenta.
- Agrupe: navegação em `browser_batch`, leituras independentes num turno só.
- Sem introdução, sem recapitular. Não assuma nada: dúvida vira pergunta.
