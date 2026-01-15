# 🚀 Guia de Build - BTC Cycle Monitor

## Pré-requisitos
- Flutter SDK instalado
- Visual Studio Build Tools instalado
- Inno Setup Compiler instalado

## Passos para Gerar o Instalador

### 1️⃣ Limpar Build Anterior (Opcional)
```powershell
flutter clean
```

### 2️⃣ Build do Flutter para Windows
```powershell
flutter build windows --release
```

**Tempo estimado:** 5-10 minutos  
**Saída:** `build\windows\x64\runner\Release\`

Os seguintes arquivos serão gerados:
- `btc_cycle_monitor.exe` - Executável principal
- `flutter_windows.dll` - DLL do Flutter
- `*.dll` - Outras DLLs necessárias
- `data\` - Pasta com assets e recursos

### 3️⃣ Compilar o Instalador com Inno Setup

#### Opção A: Via Interface Gráfica
1. Abra o **Inno Setup Compiler**
2. Clique em **File > Open** e selecione `installer.iss`
3. Clique em **Build > Compile** (ou pressione `Ctrl+F9`)
4. Aguarde a compilação

#### Opção B: Via Linha de Comando
```powershell
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer.iss
```

**Tempo estimado:** 1-2 minutos  
**Saída:** `installer_output\btc_cycle_monitor_setup.exe`

### 4️⃣ Testar o Instalador
1. Navegue até `installer_output\`
2. Execute `btc_cycle_monitor_setup.exe`
3. Siga o assistente de instalação
4. Verifique se o app foi instalado corretamente
5. Teste a execução do aplicativo

## 📁 Estrutura de Arquivos

```
btc_cycle_monitor/
├── installer.iss                    # Script do Inno Setup
├── assets/
│   └── icons/
│       └── favicon-circular.ico     # Ícone do instalador
├── build/
│   └── windows/
│       └── x64/
│           └── runner/
│               └── Release/         # Build do Flutter (gerado)
└── installer_output/                # Instalador final (gerado)
    └── btc_cycle_monitor_setup.exe
```

## ⚙️ Configurações do installer.iss

- **AppVersion:** 1.0.0
- **Ícone:** `assets\icons\favicon-circular.ico`
- **Nome do Setup:** `btc_cycle_monitor_setup.exe`
- **Idiomas:** Português (BR) e Inglês
- **Arquitetura:** x64

## 🔧 Troubleshooting

### Build falha com erro de compilação
- Verifique se o Visual Studio Build Tools está instalado
- Execute `flutter doctor` para diagnosticar problemas

### Inno Setup não encontra arquivos
- Certifique-se de que o build do Flutter foi concluído
- Verifique se os arquivos existem em `build\windows\x64\runner\Release\`

### Instalador não executa
- Execute como administrador
- Verifique se o antivírus não está bloqueando

## 📝 Notas

- O build de release é otimizado e menor que o debug
- O instalador já inclui todas as DLLs necessárias
- Não é necessário instalar o Flutter no PC do usuário final
- O app pode ser instalado sem privilégios de administrador (`PrivilegesRequired=lowest`)

## 🔄 Atualizações

Para gerar uma nova versão:
1. Atualize a versão em `pubspec.yaml`
2. Atualize `AppVersion` em `installer.iss`
3. Execute os passos 1-4 acima
4. O novo instalador sobrescreverá o anterior em `installer_output\`
