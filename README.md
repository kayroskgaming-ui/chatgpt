# Minha Vida — Histórias da Cidade

**0.1.1 · reconstrução da primeira base jogável.** Jogo de simulação de vida em português brasileiro, ambientado no Bairro Ipê de Vila Aurora. Godot **4.6.3 estável**, edição padrão GDScript, renderizador **Compatibility**.

O ambiente anterior ficou indisponível antes de ser possível transferir o ZIP. Esta versão foi reconstruída a partir do código registrado na conversa e testada novamente; não é uma recuperação byte a byte do pacote 0.1.0.

## Baixar e abrir no Windows

Depois que esta versão estiver disponível no GitHub:

1. Na página do repositório, selecione a branch `minha-vida-recuperacao`.
2. Clique no botão verde **Code** → **Download ZIP**.
3. Na pasta Downloads, clique com o botão direito no ZIP → **Extrair Tudo**.
4. Baixe o **Godot 4.6.3 padrão para Windows x64**, sem .NET, pelo site oficial: https://godotengine.org/download/archive/4.6.3-stable/.
5. Extraia e execute o Godot. Clique em **Importar**, selecione `project.godot` na pasta do jogo e abra o projeto.
6. Pressione **F5** no editor. Escolha **Criar meu personagem** e siga o tutorial.

Este pacote é um projeto editável. Não é um jogo de navegador e ainda não inclui executável Windows. O preset de exportação está incluído, mas a exportação e execução em Windows não foram validadas.

## Funcional nesta base

- Bairro isométrico com sua casa habitável, casa da Bia, praça e Café da Esquina visitável.
- Movimento por clique e teclado, caminhos por grade, paredes e móveis sólidos, portas autorizadas e fila de ações cancelável.
- Câmera com acompanhamento, deslocamento e quatro níveis de zoom.
- Telhado e fachada por fora; transição para o interior ao entrar e restauração ao sair.
- Personagem adulto com nome, quatro tons de pele, cores de cabelo, roupas, pronomes e três traços com efeitos na leitura e socialização.
- Seis necessidades, conforto, humor, ciclo dia/noite, pausa e tempo 1×/2×/3×.
- Dormir, comer marmita da geladeira, tomar banho, usar banheiro, ler, descansar e conversar. Autonomia opcional para necessidades muito baixas.
- Dois vizinhos com rotinas simples, amizade por morador e visita à Bia com aceitação ou recusa.
- Barista: segunda a sexta, 09:00–13:00, V$ 120 por turno integral. Aviso, pop-up, transporte automático, adiamento de 15 minutos, falta, posturas e salário proporcional ao atraso. Pagamento único registrado no extrato.
- Lanche por V$ 12 e café por V$ 4 no estabelecimento físico, das 08:00 às 18:00.
- Save manual e automático, arquivo temporário e cópia anterior de recuperação. Estoque, fila, posição e turno em andamento persistem sem pagamentos ou consumo duplicados.
- Inventário, destinos do bairro, amizades, extrato, opções de necessidades/autonomia, tamanho do texto e volume de música original.

## Controles

| Comando | Função |
|---|---|
| Clique no chão | Caminhar; adiciona destino à fila |
| Clique em casa, pessoa ou objeto | Ações disponíveis |
| WASD | Andar diretamente e cancelar ações anteriores |
| Roda do mouse | Zoom |
| Arrastar com botão do meio | Mover câmera |
| C | Voltar a seguir o personagem |
| Espaço / 1 / 2 / 3 | Pausa / velocidades |
| X | Cancelar fila, inclusive dormir |
| F5 / F9 na janela do jogo | Salvar / carregar |
| M / Esc | Destinos do bairro / menu |
| F3 | Depuração de colisões, rotas e pontos de uso |

F5 no editor inicia o projeto; F5 na janela do jogo salva.

## Limitações e próximas etapas

É uma base funcional para jogar um dia completo, com arte procedural original e animações provisórias. Há um penteado e poses simples; não há o conjunto final de sprites direcionais. A aspiração é fixa. Não há cômodos separados, portas animadas, diálogos variados ou simulação detalhada de necessidades dos NPCs.

A casa é cedida. Aluguel, contas, imobiliária, supermercado, culinária, validade dos alimentos, entregas, decoração, outras carreiras, promoções, romance, famílias, outros bairros, veículos, trânsito, negócios próprios e controle Xbox **ainda não estão implementados**. O menu M é uma lista de destinos, sem mapa ilustrado.

A próxima entrega deve aprimorar o acabamento da Etapa 1 antes de avançar para moradia e compras. Os módulos de sistemas futuros serão acrescentados quando houver funções reais, sem telas fictícias.

## Testes e desenvolvimento na nuvem

```bash
bash tools/setup.sh   # versão da engine, importação e testes
bash tools/check.sh   # 40 verificações de simulação/save + 16 de interface
bash tools/start.sh   # requer display gráfico
```

Os scripts usam diretórios graváveis em `/workspace/.runtime` para dados/config/cache. Em um computador comum, abra pelo editor: o save fica na pasta `user://` padrão do Godot, em `vida.json` e `vida.json.bak`. Os testes usam nomes de arquivo próprios, sem sobrescrever seu jogo.

- `scripts/city.gd`: mapa, objetos, propriedades, acesso e busca de caminhos.
- `scripts/simulation.gd`: relógio, necessidades, ações, estoque, economia, trabalho e vizinhos.
- `scripts/world.gd`: projeção isométrica, arte, câmera, poses e telhados.
- `scripts/main.gd`: interface, controles, menus, opções e autosave.
- `scripts/save_store.gd`: serialização, validação básica, backup e recuperação.
- `assets/aurora.wav`: música original sintetizada, sem amostras externas.
- `tests/`: suítes de simulação e interface real.

## Validação da reconstrução

Em Linux, com Godot 4.6.3: **40 verificações de simulação/save e 16 de interface passaram**. Cobrem um dia em 3×, uso dos móveis, visitas aceitas/recusadas, compra, fila bloqueada, turno, pagamento único, save corrompido e retomada de refeição/expediente. O teste de interface instancia a cena real e aciona seus botões.

Os resultados estão em [docs/testes.txt](docs/testes.txt). O conjunto não substitui avaliação humana prolongada nem execução no Windows. A cena também foi executada em display Xorg virtual, com OpenGL Compatibility/Mesa llvmpipe; o interior foi inspecionado. Capturas reais estão em `docs/capturas/`. Não houve avaliação sonora por escuta humana.
