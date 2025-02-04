const puppeteer = require('puppeteer');

async function scrapeProblem(contestId, index) {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  await page.goto(`https://codeforces.com/problemset/problem/${contestId}/${index}`);

  const problemDetails = await page.evaluate(() => {
    const title = document.querySelector('.title').innerText;
    const statement = document.querySelector('.problem-statement > div:nth-child(2)').innerText;
    const inputSpec = document.querySelector('.input-specification').innerText;
    const outputSpec = document.querySelector('.output-specification').innerText;
    
    const examples = [];
    const inputs = document.querySelectorAll('.input pre');
    const outputs = document.querySelectorAll('.output pre');
    
    for (let i = 0; i < inputs.length; i++) {
      examples.push({
        input: inputs[i].innerText,
        output: outputs[i].innerText
      });
    }

    return {
      title,
      statement,
      inputSpec,
      outputSpec,
      examples
    };
  });

  await browser.close();
  return problemDetails;
}

module.exports = { scrapeProblem };