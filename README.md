# 🚗 EcoRoute - Aplicativo de Mobilidade Sustentável

Um aplicativo Flutter para rastreamento de rotas e promoção da mobilidade sustentável, permitindo aos usuários monitorar suas viagens e ganhar pontos por escolhas ecológicas.

## 📱 Sobre o Projeto

O EcoRoute é um aplicativo móvel que incentiva a mobilidade sustentável através de:
- Rastreamento de rotas em tempo real
- Sistema de pontuação baseado no meio de transporte utilizado
- Perfil personalizado com avatares e veículos
- Estatísticas de impacto ambiental
- Interface moderna e intuitiva

## 🛠️ Tecnologias Utilizadas

- **Flutter** - Framework de desenvolvimento mobile
- **Dart** - Linguagem de programação
- **HTTP** - Para comunicação com APIs
- **Shared Preferences** - Armazenamento local
- **Geolocator** - Serviços de localização
- **Permission Handler** - Gerenciamento de permissões

## 📋 Pré-requisitos

Antes de começar, certifique-se de ter instalado em sua máquina:

### 1. Flutter SDK
- **Versão mínima:** Flutter 3.0.0
- **Download:** [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)

### 2. Dart SDK
- Incluído com o Flutter SDK

### 3. Editor de Código
- **VS Code** (recomendado) com extensões Flutter e Dart
- **Android Studio** com plugins Flutter e Dart
- **IntelliJ IDEA** com plugins Flutter e Dart

### 4. Configuração de Dispositivos

#### Para Android:
- **Android Studio** instalado
- **Android SDK** (API level 21 ou superior)
- **Emulador Android** ou dispositivo físico com depuração USB habilitada

#### Para iOS (apenas no macOS):
- **Xcode** (versão mais recente)
- **iOS Simulator** ou dispositivo físico
- **CocoaPods** instalado

## 🚀 Instalação e Configuração

### 1. Clone o Repositório
```bash
git clone https://github.com/seu-usuario/flutter_tcc.git
cd flutter_tcc
```

### 2. Verifique a Instalação do Flutter
```bash
flutter doctor
```
> Este comando verifica se todas as dependências estão instaladas corretamente.

### 3. Instale as Dependências
```bash
flutter pub get
```

### 4. Configuração de Ambiente

#### Crie o arquivo de configuração de ambiente:
```bash
# Crie o arquivo lib/config/environment_config.dart se não existir
```

#### Configure as variáveis de ambiente necessárias:
```dart
// lib/config/environment_config.dart
class EnvironmentConfig {
  static const String baseUrl = 'https://sua-api.com/api';
  // Adicione outras configurações necessárias
}
```

### 5. Configuração de Permissões

#### Android (android/app/src/main/AndroidManifest.xml):
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

#### iOS (ios/Runner/Info.plist):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Este app precisa de acesso à localização para rastrear suas rotas.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Este app precisa de acesso à localização para rastrear suas rotas em segundo plano.</string>
```

## 🏃‍♂️ Executando o Projeto

### 1. Verifique os Dispositivos Disponíveis
```bash
flutter devices
```

### 2. Execute o Aplicativo

#### Em modo de desenvolvimento:
```bash
flutter run
```

#### Em um dispositivo específico:
```bash
flutter run -d <device-id>
```

#### Em modo release:
```bash
flutter run --release
```

### 3. Hot Reload
Durante o desenvolvimento, você pode usar:
- **r** - Hot reload
- **R** - Hot restart
- **q** - Quit

## 🔧 Scripts Úteis

### Limpeza do Projeto
```bash
flutter clean
flutter pub get
```

## 📁 Estrutura do Projeto

```
lib/
├── config/              # Configurações da aplicação
├── models/              # Modelos de dados
├── screens/             # Telas da aplicação
├── services/            # Serviços e APIs
│   ├── auth/           # Serviços de autenticação
│   ├── user/           # Serviços de usuário
│   ├── route/          # Serviços de rotas
│   └── validation/     # Validação e tratamento de erros
├── widgets/            # Widgets reutilizáveis
└── main.dart           # Ponto de entrada da aplicação
```

## 🔐 Configuração da API

### 1. Backend
Certifique-se de que o backend esteja rodando e acessível.

### 2. Configuração da URL
Atualize a `baseUrl` no arquivo `lib/config/environment_config.dart`:
```dart
class EnvironmentConfig {
  static const String baseUrl = 'http://localhost:8000/api'; // Para desenvolvimento local
  // ou
  static const String baseUrl = 'https://sua-api-producao.com/api'; // Para produção
}
```

## 📱 Funcionalidades Principais

### Autenticação
- Login com email e senha
- Cadastro de novos usuários
- Recuperação de senha
- Confirmação por token

### Perfil do Usuário
- Configuração inicial do perfil
- Seleção de avatar personalizado
- Escolha do veículo principal
- Estatísticas pessoais

### Rastreamento de Rotas
- Gravação de rotas em tempo real
- Cálculo automático de pontos
- Histórico de viagens
- Impacto ambiental

## 🐛 Solução de Problemas

### Problemas Comuns

#### 1. Erro de dependências
```bash
flutter clean
flutter pub get
```

#### 2. Problemas de permissão de localização
- Verifique se as permissões estão configuradas corretamente
- Teste em um dispositivo físico
- Certifique-se de que o GPS está habilitado

#### Debug no VS Code:
1. Abra o projeto no VS Code
2. Pressione `F5` ou vá em `Run > Start Debugging`
3. Selecione o dispositivo desejado