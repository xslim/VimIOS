# VimIOS - A port of Vim to iOS 9+

*Disclaimer*: This is a side project of mine - no promises and no warranties. If you like it, feel free to let me know, and please feel free to improve on it, there is a lot to do.

This project is based on the [Vim port of applidium](https://github.com/applidium/Vim), which has been inactive for a few years. Nonetheless, it is a full port of Vim, but since its inceptions, iOS has gained many features of which this port did not take advantage. I large parts of it with the goal of improving the Vim experience under iOS 9, in particular on iPads with an external keyboard. 

The new key features are:

* Split View and Slide Over support
* Full external keyboard support
* Importing and exporting files from Vim to other apps is now possible. 
* The app now looks great on retina displays.
* Upgrade to Vim 7.4

## Acknowledgements
Obviously, I used the code of [Applidiums Vim port](https://github.com/applidium/Vim), and Vim itself. I had to make minor changes in the Vim source code a few times, so I include a modified version of the [Vim code base](https://github.com/vim/vim). Note that Vim is charity ware, see [here for the Vim license](http://vimdoc.sourceforge.net/htmldoc/uganda.html#license). The app icon was taken from [here](http://usevim.com/2014/07/25/flat-vim-icons/).

## Setup
Clone the repository and use XCode to compile it for your iOS 9+ device. *Caveat:* While the project compiles in the XCode 7.3 Beta, execution of the app terminates in an obscure part of the original Vim code. Strangely enough, if the app was compiled with XCode 7.2, this does not happen. I will wait for the final version of XCode 7.3, and then see if the problem persists and if I can fix it.

## Usage
Open the app and just start typing. If you have an external keyboard, you should be all set. If you need an escape key, or F1, longpress anywhere on the screen. This will open a tool bar with a few buttons. But instead of escape, you can also use `<C-[>`. 

You can get this help by using the command `:help ios`.

### File management.
This version of Vim comes with a version of the netrw file browser. Use the command `e .` to start it. You will likely see the following items:

```
.vim/
Inbox/
.viminfo
.vimrc
```
If `.vimrc` does not exist, you can create it, if you wish. 

You can write your files anywhere, except for the `Inbox/` folder, see below.
Use `F1` to get help on how to use the file browser. You can create directories with `d` and delete directories/files with `D'. 

### The Inbox folder
This is a special folder. Files imported from other applications will be saved there. **Note that you cannot save to the Inbox folder manually**. In particular, if you import a file and make changes, then you *have* to save the new file somewhere outside the Inbox folder.

### Importing files from other applications
If you would like to edit a file in Vim that is currently in the sandbox of another application (e.g. the brilliant [Working Copy](http://workingcopyapp.com)), simply go to this app and use standard iOS dialog "Open in another app". Pick VimIOS, the file will be copied to the VimIOS sandbox, and Vim will be opened. Similarly, if you receive a text file via Airdrop, you can open it in VimIOS.

**Important**: The file will be imported and saved into the directory `Inbox`. If you want to make changes to this file, you **have** to save it outside the `Inbox` directory. 

## Exporting files to other applications
I added two commands to commands to Vim which allow you to export files.
 
* `:Share` opens the standard iOS dialog "Open in other app". You can also export your file via Airdrop.
* `:Mail` opens a slightly different dialog, which allows you to export your text as the body of an email. 

## Customization
In the `.vim` folder (create it, if it doesn't exist), you can add plugins and themes as usual. I have not tested many plugins; obviously those utilizing many features external to Vim will not work, as iOS does not provide a shell to Vim.

You can create and customize a `.vimrc` file as usual. Some graphical features will probably not work. 

## Todo:
It would be very nice to implement the new iOS document picker feature, which would allow Vim to open files directly from the sandbox of a (compatible) app, such as several cloud storage providers. Unfortunately, by someone with an Apple Developer subscription, as access to CloudKit is necessary. Also note that this would require the implementation of an at least rudimentary document management system, as the document picker extension works with the UIDocument class.
