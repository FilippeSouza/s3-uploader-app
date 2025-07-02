const express = require('express');
const multer = require('multer');
const { S3Client } = require('@aws-sdk/client-s3');
const multerS3 = require('multer-s3');

// 1. Configurar o Cliente S3 - Versão para Nuvem
// Ele não precisa de nenhuma configuração. O SDK da AWS encontrará
// as permissões automaticamente através do IAM Role do App Runner.
const s3Client = new S3Client({});

// 2. Configurar o Multer para fazer o upload para o S3
const upload = multer({
    storage: multerS3({
        s3: s3Client,
        bucket: "welcome-ecopower", // Usando o nome do bucket diretamente
        acl: 'public-read',
        metadata: function (req, file, cb) {
            cb(null, { fieldName: file.fieldname });
        },
        key: function (req, file, cb) {
            const fileName = `envios_linux/${Date.now().toString()}-${file.originalname}`;
            cb(null, fileName);
        }
    })
});

// 3. Inicializar a aplicação Express
const app = express();
// O App Runner nos informa em qual porta ele quer que a aplicação rode.
// Devemos usar a variável de ambiente PORT que ele fornece.
const PORT = process.env.PORT || 3000;

app.use(express.static('public'));

app.post('/upload', upload.single('file'), (req, res) => {
    if (!req.file) {
        return res.status(400).send('Nenhum arquivo foi enviado.');
    }
    console.log('Arquivo enviado com sucesso:', req.file);
    res.status(200).json({ 
        message: 'Arquivo enviado com sucesso!',
        url: req.file.location 
    });
});

// 4. Iniciar o servidor
app.listen(PORT, () => {
    console.log(`Servidor rodando na porta ${PORT}`);
});