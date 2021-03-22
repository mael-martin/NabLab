# Getting started

## Download and install

### Prerequisite

NabLab requires [Java 11](https://openjdk.java.net/projects/jdk/11/) or later to build & run. 

Do not forget to set the `JAVA_HOME` variable to the java installation directory and to update your path.


### Installing NabLab

The latest NabLab environment can be downloaded [here](https://github.com/cea-hpc/NabLab/releases/tag/v0.4.0).
 
Download the file corresponding to your platform, unzip it and lauch the NabLab executable in the root directory.

For Mac users, depending on your security configuration, you have to enter the following command to execute NabLab: `xattr -d com.apple.quarantine NabLab.app`.


### Installing NabLab debugger

NabLab debugger is based on [GraalVM](https://www.graalvm.org/) and [Monilog](https://github.com/gemoc/monilog). It is still under development. The temporary installation process is:

1. Download GraalVM community edition 21.0.0 [here](https://github.com/graalvm/graalvm-ce-builds/releases/tag/vm-21.0.0) and extract it in the directory of your choice.

2. Install Graalpython in following the instructions available [here](https://www.graalvm.org/reference-manual/python/). Note that numpy is a supported package of GraalVM: just replace `pandas` by `numpy` in the [package installation instructions](https://www.graalvm.org/reference-manual/python/#installing-supported-packages). 

3. For Monilog and GraalVM support of NabLab, download the 3 files available [here](https://filesender.renater.fr/?s=download&token=13f443c8-71d5-4da0-adcf-469abd9aeff6). To install the NabLab and Monilog languages support for GraalVM, type the following command: `/path/to/graalvm/bin/gu -L install -f nabla-component.jar`. Then create the folder `/path/to/graalvm/tools/monilogger` and copy the file `monilogger.jar` into it.

4. Into your NabLab product, click on the menu *Help > Install New Software...*, a dialog box appears, clic on *Add... > Archive* and select the `graalvm-integration.zip` file.

5. In the root directory of your NabLab installation, add the following option to the NabLab.ini file `-vm /path/to/graalvm-ce-java11-21.0.0/bin/java`.


### Build via Maven 3.x

If you need to build NabLab products (Windows/Linux/MacOS and Eclipse update-site) from the source code (instead of downloading it), run the following command from the root of the repository:

`mvn clean; mvn verify`.

Note the `';'` after `mvn clean`. 

The products resulting from the build will be accessible in */releng/fr.cea.nabla.updatesite/target/products/NabLab-X.Y.Z.yyyymmddHHMM-YOUR_PLATFORM.zip*.

The Eclipse update-site resulting from the build will be accessible in */releng/fr.cea.nabla.updatesite/target/fr.cea.nabla.updatesite-X.Y.Z.yyyymmddHHMM.zip*.

If you want to skip tests execution, you can run the following command:
`mvn clean; mvn verify -Dmaven.test.skip=true`


## First step in the environment

### Perspective

Once the NabLab environment has been launched, the NabLab perspective should be selected. If it is not the case, just select the NabLab perspective from the *Window > Perspective > Open Perspective > Other ... > NabLab* menu.

<img src="/images/gettingstarted/NabLab_perspective_menu.png" alt="NabLab Perspective Menu" title="NabLab Perspective Menu" width="40%" height="40%" />

The NabLab perspective provides a set of *Views* and wizards shortcuts allowing to easily create and develop NabLab projects.


### Examples project

Just click on the main menu From the *File > New > NabLab Examples* to import the examples project:

<img src="/images/gettingstarted/NabLab_new_menu.png" alt="NabLab Examples" title="NabLab Examples" width="40%" height="40%" />

A new wizard is launched:

<img src="/images/gettingstarted/NabLab_examples_wizard.png" alt="NabLab Examples Wizard" title="NabLab Examples Wizard" width="80%" height="80%" />

Just click on the *Finish* button to import the examples project that becomes available in the *Model Explorer* view on the left of the perspective. It contains a set of examples including Glace2D, HeatEquation, ExplicitHeatEquation, IterativeHeatEquation and ImplicitHeatEquation.

<img src="/images/gettingstarted/NabLab_examples_generated_files.png" alt="NabLab Examples Generated Files" title="NabLab Examples Generated Files" width="100%" height="100%" />


### Code generation

To launch code generation corresponding to the NabLab module, just right-click on the ngen file of the project of your choice, for example *NabLabExamples/src/explicitheatequation/ExplicitHeatEquation.ngen* and select *Generate Code*

<img src="/images/gettingstarted/NabLab_generate_code.png" alt="NabLab Generate Code" title="NabLab Generate Code" width="50%" height="50%" />

Java and C++ source code files are generated in *src-gen-java* and *src-gen-cpp* folders respectively. For each C++ folder a CMakeLists.txt file is generated.
A LaTeX file containing the content of the jobs and an example of json data file are also generated in the *src-gen* folder.  

<img src="/images/gettingstarted/NabLab_generated_files.png" alt="NabLab Generated Files" title="NabLab Generated Files" width="30%" height="30%" />


### LaTeX view

The *LaTeX View* is located on the bottom of the NabLab environment. It allows to visualize in an elegant way the formulas contained in a .n file.

If you do not use the NabLab perspective the *The LaTeX View* is not visible. You can access it through the *Window > Show View > Other... > NabLab > LaTeX View* main menu.

This view is automatically updated and synchronized with the selection in the current NabLab editor.

<img src="/images/gettingstarted/NabLab_latex_view.png" alt="NabLab Latex View" title="NabLab Latex View" width="100%" height="100%" />


### Job graph view

The *Job Graph View* can be opened from a *ngen* file containing an *Application*, by clicking on F1.

It allows to quickly visualize the data flow graph of the application described in the ngen file.

<img src="/images/gettingstarted/NabLab_job_graph_view.png" alt="NabLab Job Graph View" title="NabLab Job Graph View" width="100%" height="100%" />


### Job graph editor

NabLab offers another way of visualizing the data flow graph of an application.

The *Job Graph Editor* can be opened from a *ngen* file containing an *Application*, by clicking on F2.

It allows to visualize bigger graphs than the *Job Graph View* thanks to an efficient layout.

<img src="/images/gettingstarted/NabLab_job_graph_editor.png" alt="NabLab Job Graph Editor" title="NabLab Job Graph Editor" width="100%" height="100%"/>
