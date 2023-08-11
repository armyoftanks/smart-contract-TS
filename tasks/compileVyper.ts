import { task } from 'hardhat/config';
import execa from 'execa';
import fs from 'fs';
import path from 'path';

task('compile-vyper', 'Compile Vyper contracts')
  .setAction(async (_, hre) => {
    const contractsDir = path.join(__dirname, '..', 'contracts');
    const artifactsDir = path.join(__dirname, '..', 'artifacts', 'build');

    if (!fs.existsSync(artifactsDir)) {
      fs.mkdirSync(artifactsDir, { recursive: true });
    }

    const vyperFiles = fs.readdirSync(contractsDir).filter((file) => file.endsWith('.vy'));

    for (const vyperFile of vyperFiles) {
      const vyperFilePath = path.join(contractsDir, vyperFile);
      const compiledOutputPath = path.join(artifactsDir, vyperFile.replace('.vy', '.json'));

      try {
        await execa('vyper', [vyperFilePath, '--format=json', '-o', compiledOutputPath]);
        console.log(`Compiled: ${vyperFile}`);
      } catch (error) {
        console.error(`Error compiling ${vyperFile}: ${error.message}`);
      }
    }
  });

export default {};
