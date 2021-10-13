echo "--------------------------------"
echo "Instalação do Whaticket - RCATech"
echo "--------------------------------"

echo "Favor, entrar com a URL do BackEnd"
read BACKEND_URL
echo "Entrar com a URL do FrontEnd"
read FRONTEND_URL
echo "Favor, entrar com o local de Hosteio."
read DB_HOST
echo "Entrar com o usuário do Banco de Dados"
read DB_USER 
echo "Entrar com a senha do Banco de Dados"
read DB_PASS
echo "Entrar com o nome do Banco de dados"
read DB_NAME 
echo "Perfeito. Utilizando os dados informados para a instalação."

echo "Adicionando usuario deploy"
adduser deploy
echo "Dando permissões"
usermod -aG sudo deploy
echo "Trocando para o novo usuario"
su deploy
echo "Atualizando"
sudo apt update && sudo apt upgrade
echo "Buscando node para instalação"
curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
echo "Instalando node"
sudo apt-get install -y nodejs
echo "Versão instalada:"
node -v
echo "Versão do NPM:"
npm -v

echo "Criando nova pasta e indo a ela para clonar o repositório."
cd ~
echo "Baixando... Aguarde."
git clone https://github.com/canove/whaticket whaticket
echo "Download concluído. Entrando na pasta e criando o ambiente configuravel."
cp whaticket/backend/.env.example whaticket/backend/.env
echo "Nesta parte, é necessário que voce informe as informações para criação do ambiente."
nano whaticket/backend/.env





#!/usr/bin/env bash

# Inspired by implementation by Will Haley at:
#   http://willhaley.com/blog/generate-jwt-with-bash/

set -o pipefail

# Shared content to use as template
header_template='{
    "typ": "JWT",
    "kid": "0001",
    "iss": "https://stackoverflow.com/questions/46657001/how-do-you-create-an-rs256-jwt-assertion-with-bash-shell-scripting"
}'

build_header() {
        jq -c \
                --arg iat_str "$(date +%s)" \
                --arg alg "${1:-HS256}" \
        '
        ($iat_str | tonumber) as $iat
        | .alg = $alg
        | .iat = $iat
        | .exp = ($iat + 1)
        ' <<<"$header_template" | tr -d '\n'
}

b64enc() { openssl enc -base64 -A | tr '+/' '-_' | tr -d '='; }
json() { jq -c . | LC_CTYPE=C tr -d '\n'; }
hs_sign() { openssl dgst -binary -sha"${1}" -hmac "$2"; }
rs_sign() { openssl dgst -binary -sha"${1}" -sign <(printf '%s\n' "$2"); }

sign() {
        local algo payload header sig secret=$3
        algo=${1:-RS256}; algo=${algo^^}
        header=$(build_header "$algo") || return
        payload=${2:-$test_payload}
        signed_content="$(json <<<"$header" | b64enc).$(json <<<"$payload" | b64enc)"
        case $algo in
                HS*) sig=$(printf %s "$signed_content" | hs_sign "${algo#HS}" "$secret" | b64enc) ;;
                RS*) sig=$(printf %s "$signed_content" | rs_sign "${algo#RS}" "$secret" | b64enc) ;;
                *) echo "Unknown algorithm" >&2; return 1 ;;
        esac
        printf '%s.%s\n' "${signed_content}" "${sig}"
}

(( $# )) && sign "$@"





NODE_ENV=
BACKEND_URL=https://api.mydomain.com      #USE HTTPS HERE, WE WILL ADD SSL LATTER
FRONTEND_URL=https://myapp.mydomain.com   #USE HTTPS HERE, WE WILL ADD SSL LATTER, CORS RELATED!
PROXY_PORT=443                            #USE NGINX REVERSE PROXY PORT HERE, WE WILL CONFIGURE IT LATTER
PORT=8080

DB_HOST=localhost
DB_DIALECT=
DB_USER=
DB_PASS=
DB_NAME=

JWT_SECRET=3123123213123
JWT_REFRESH_SECRET=75756756756

echo "Instalando as dependências do Puppeteer."
sudo apt-get install -y libxshmfence-dev libgbm-dev wget unzip fontconfig locales gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils

echo "Redirecionando para o Backend e instalar e atualizar."
cd whaticket/backend
npm install
npm run build
npx sequelize db:migrate
npx sequelize db:seed:all

sudo npm install -g pm2
pm2 start dist/server.js --name whaticket-backend
pm2 startup ubuntu -u `YOUR_USERNAME`
sudo env PATH=\$PATH:/usr/bin pm2 startup ubuntu -u YOUR_USERNAME --hp /home/YOUR_USERNAM

echo "Redirecionando para o Frontend para instalar e atualizar."
cd ../frontend
npm install
REACT_APP_BACKEND_URL = https://api.mydomain.com/
npm run build
pm2 start server.js --name whaticket-frontend
pm2 save

echo "Lista de como está o status do front e backend."
pm2 list
echo "Caso esta lista não conte com 2 linhas, cada qual representando uma parte da aplicação. Reproduzir os passos acima novamente."
sudo apt install nginx
sudo rm /etc/nginx/sites-enabled/default
sudo nano /etc/nginx/sites-available/whaticket-frontend

server {
  server_name myapp.mydomain.com;
  location / {
    proxy_pass http://127.0.0.1:3333;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_cache_bypass $http_upgrade;
  }
}

sudo cp /etc/nginx/sites-available/whaticket-frontend /etc/nginx/sites-available/whaticket-backend
sudo nano /etc/nginx/sites-available/whaticket-backend

server {
  server_name api.mydomain.com;
  location / {
    proxy_pass http://127.0.0.1:8080;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_cache_bypass $http_upgrade;
  }
}

sudo ln -s /etc/nginx/sites-available/whaticket-frontend /etc/nginx/sites-enabled
sudo ln -s /etc/nginx/sites-available/whaticket-backend /etc/nginx/sites-enabled

sudo nano /etc/nginx/nginx.conf
http {
    client_max_body_size 20M; # HANDLE BIGGER UPLOADS
}
sudo nginx -t
sudo service nginx restart

sudo add-apt-repository ppa:certbot/certbot
sudo apt update
sudo apt install python-certbot-nginx
sudo certbot --nginx

