function mostrarSecao(id) {

    let secoes = document.querySelectorAll(".secao");

    secoes.forEach(function(secao) {

        secao.classList.remove("ativa");

    });


    let secaoEscolhida = document.getElementById(id);

    secaoEscolhida.classList.add("ativa");
}



function responder(correta) {

    let resposta = document.getElementById("respostaQuiz");


    if (correta == true) {

        resposta.innerText =
            "✅ Correto! A lactucina é um dos compostos estudados no projeto.";

    } else {

        resposta.innerText =
            "❌ Não é essa! Tente novamente.";

    }

}