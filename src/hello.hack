use namespace HH\Lib\IO;

<<__EntryPoint>>
async function main(): Awaitable<void> {
  require_once(__DIR__.'/../vendor/autoload.hack');
  Facebook\AutoloadMap\initialize();
  await IO\request_output()->writeAllAsync("Hello World!\n");
}
